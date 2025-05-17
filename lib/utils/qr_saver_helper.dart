import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:ui' as ui;

class QRSaverHelper {
  static Future<void> saveQRImage(
      BuildContext context, GlobalKey qrKey, String type) async {
    try {
      print('Starting QR image save process...');

      bool permissionGranted = false;

      if (Platform.isAndroid) {
        // Android permission handling
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        final androidVersion = deviceInfo.version.sdkInt;
        print('Android version: $androidVersion');

        if (androidVersion >= 33) {
          print('Requesting Photos permission for Android 13+');
          permissionGranted = await Permission.photos.request().isGranted;
        } else {
          print('Requesting Storage permission for Android 12 or below');
          permissionGranted = await Permission.storage.request().isGranted;
        }
      } else if (Platform.isIOS) {
        // iOS permission handling
        print('Requesting Photos permission for iOS');
        permissionGranted = await Permission.photos.request().isGranted;
      }

      if (!permissionGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Photo library access is required to save QR code')),
          );
        }
        return;
      }

      print('Capturing QR code image...');
      // Add a small delay to ensure widget is rendered
      await Future.delayed(Duration(milliseconds: 300));

      // Capture QR code image
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        print('Error: Failed to get RenderRepaintBoundary');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to capture QR code')),
          );
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      print('QR code captured as image');

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      print('Image converted to bytes');

      if (byteData == null) {
        print('Error: Failed to get image byte data');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to process QR code image')),
          );
        }
        return;
      }

      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/qr_${type}_$timestamp.png');
      print('Saving to temporary file: ${tempFile.path}');

      await tempFile.writeAsBytes(byteData.buffer.asUint8List());
      print('Temporary file created');

      // Save to gallery
      print('Attempting to save to gallery...');
      final success = await GallerySaver.saveImage(
        tempFile.path,
        albumName:
            Platform.isIOS ? 'QR Codes' : null, // Album name only for iOS
        toDcim: Platform.isAndroid, // Save to DCIM on Android
      );
      print('Gallery save result: $success');

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
        print('Temporary file deleted');
      }

      if (success == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR code saved to gallery'),
              action: Platform.isAndroid
                  ? SnackBarAction(
                      label: 'View',
                      onPressed: () async {
                        // Try to open gallery (Android only)
                        final galleryDir =
                            Directory('/storage/emulated/0/Pictures/QR Codes');
                        if (await galleryDir.exists()) {
                          final uri = Uri.file(galleryDir.path);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        }
                      },
                    )
                  : null,
            ),
          );
        }
      } else {
        print('Error: Gallery save returned false');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save QR code to gallery')),
          );
        }
      }
    } catch (e) {
      print('Error in saveQRImage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving QR code: $e')),
        );
      }
    }
  }
}
