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
      // Check Android version and request appropriate permissions
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final androidVersion = deviceInfo.version.sdkInt;
      bool permissionGranted = false;

      if (androidVersion >= 33) {
        // Android 13 and above: Request Photos permission
        permissionGranted = await Permission.photos.request().isGranted;
      } else {
        // Android 12 and below: Request Storage permission
        permissionGranted = await Permission.storage.request().isGranted;
      }

      if (!permissionGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Storage permission is required to save QR code')),
          );
        }
        return;
      }

      // Capture QR code image
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to capture QR code')),
          );
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
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
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      // Save to gallery
      final success =
          await GallerySaver.saveImage(tempFile.path, albumName: 'QR Codes');

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (success == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR code saved to gallery'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () async {
                  // Try to open gallery
                  final galleryDir =
                      Directory('/storage/emulated/0/Pictures/QR Codes');
                  if (await galleryDir.exists()) {
                    final uri = Uri.file(galleryDir.path);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  }
                },
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save QR code to gallery')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving QR code: $e')),
        );
      }
    }
  }
}
