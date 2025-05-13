import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../../utils/qr_history_helper.dart';

class EventResultScreen extends StatefulWidget {
  final String title;
  final String location;
  final String description;
  final DateTime startDate;
  final DateTime endDate;

  const EventResultScreen({
    Key? key,
    required this.title,
    required this.location,
    required this.description,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _EventResultScreenState createState() => _EventResultScreenState();
}

class _EventResultScreenState extends State<EventResultScreen> {
  String get eventData => '''BEGIN:VEVENT
SUMMARY:${widget.title}
LOCATION:${widget.location}
DESCRIPTION:${widget.description}
DTSTART:${_formatDateTime(widget.startDate)}
DTEND:${_formatDateTime(widget.endDate)}
END:VEVENT''';

  String _formatDateTime(DateTime dt) {
    return dt.toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.')[0] +
        'Z';
  }

  @override
  void initState() {
    super.initState();
    QRHistoryHelper.saveQRToHistoryAfterBuild(
      context,
      title: 'Event',
      content: widget.title,
      iconPath: 'assets/icons/event.png',
      additionalData: {
        'title': widget.title,
        'location': widget.location,
        'description': widget.description,
        'startDate': widget.startDate.toIso8601String(),
        'endDate': widget.endDate.toIso8601String(),
      },
    );
  }

  Future<void> _saveQRImage(BuildContext context, GlobalKey qrKey) async {
    try {
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final directory = await getApplicationDocumentsDirectory();
          final imagePath = '${directory.path}/event_qr.png';
          final buffer = byteData.buffer.asUint8List();
          final file = File(imagePath);
          await file.writeAsBytes(buffer);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR Code saved successfully!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR Code')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonth(date.month)} ${date.year}';
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final qrKey = GlobalKey();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Result',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.purple,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Calender',
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
                    data: eventData,
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
                    onTap: () => Share.share(eventData),
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share Text',
                    onTap: () => Share.share(
                      'Event Name: ${widget.title}\n'
                      'Starting Date: ${_formatDate(widget.startDate)}\n'
                      'Ending Date: ${_formatDate(widget.endDate)}\n'
                      'Location: ${widget.location}\n'
                      'Description: ${widget.description}',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Event Name: ${widget.title}\n'
                      'Starting Date: ${_formatDate(widget.startDate)}\n'
                      'Ending Date: ${_formatDate(widget.endDate)}\n'
                      'Location: ${widget.location}\n'
                      'Description: ${widget.description}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
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
