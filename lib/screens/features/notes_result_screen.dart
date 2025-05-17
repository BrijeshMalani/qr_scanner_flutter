import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../../utils/qr_history_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class NotesResultScreen extends StatefulWidget {
  final String title;
  final String content;

  const NotesResultScreen({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  _NotesResultScreenState createState() => _NotesResultScreenState();
}

class _NotesResultScreenState extends State<NotesResultScreen> {
  String get noteData => widget.content;

  @override
  void initState() {
    super.initState();
    QRHistoryHelper.saveQRToHistoryAfterBuild(
      context,
      title: 'Note',
      content: widget.content,
      iconPath: 'assets/icons/note.png',
      additionalData: {
        'title': widget.title,
        'content': widget.content,
      },
    );
  }

  Future<void> _saveQRImage(BuildContext context, GlobalKey qrKey) async {
    try {
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      if (!statuses[Permission.storage]!.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Storage permission is required to save QR code')),
        );
        return;
      }

      // Capture the QR code image
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture QR code')),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process QR code image')),
        );
        return;
      }

      // Try different directories for saving
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        // Fallback to app's external storage if Download is not accessible
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access storage directory')),
        );
        return;
      }

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'qr_code_$timestamp.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Save the file
      await file.writeAsBytes(byteData.buffer.asUint8List());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code saved to Downloads'),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            onPressed: () async {
              if (Platform.isAndroid) {
                final uri = Uri.parse(
                    'content://com.android.externalstorage.documents/document/primary%3ADownload%2F$fileName');
                try {
                  await launchUrl(uri);
                } catch (e) {
                  // If can't open file directly, try to open the Downloads folder
                  final folderUri = Uri.parse(
                      'content://com.android.externalstorage.documents/document/primary%3ADownload');
                  await launchUrl(folderUri);
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Error saving QR code: $e'); // Add debug logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR Code: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrKey = GlobalKey();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Result',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.note_alt,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'QR has been Created',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RepaintBoundary(
                  key: qrKey,
                  child: QrImageView(
                    data: noteData,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'Save QR Image',
                    onTap: () => _saveQRImage(context, qrKey),
                  ),
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'Share QR Code',
                    onTap: () => Share.share(noteData),
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share Text',
                    onTap: () => Share.share(noteData),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  noteData,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
