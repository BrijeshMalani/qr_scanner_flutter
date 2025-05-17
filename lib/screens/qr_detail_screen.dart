import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/history_item.dart';
import '../utils/qr_history_helper.dart';
import '../utils/colors.dart';
import '../services/service_provider.dart';
import '../utils/qr_saver_helper.dart';

class QRDetailScreen extends StatefulWidget {
  final HistoryItem item;

  const QRDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<QRDetailScreen> createState() => _QRDetailScreenState();
}

class _QRDetailScreenState extends State<QRDetailScreen> {
  final qrKey = GlobalKey();
  bool get isUrl => Uri.tryParse(_getQRData())?.hasScheme ?? false;
  bool get isVCard => _getQRData().trim().startsWith('BEGIN:VCARD');
  bool get isSMS => _getQRData().trim().startsWith('SMSTO:');
  bool get isEmail => _getQRData().trim().startsWith('MAILTO:');
  Map<String, String> _contactInfo = {};
  Map<String, String> _smsInfo = {};
  Map<String, String> _emailInfo = {};

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    if (widget.item.additionalData != null) {
      if (isVCard) {
        _contactInfo = Map<String, String>.from(widget.item.additionalData!);
      } else if (isSMS) {
        _smsInfo = Map<String, String>.from(widget.item.additionalData!);
      } else if (isEmail) {
        _emailInfo = Map<String, String>.from(widget.item.additionalData!);
      }
    }
  }

  String _getQRData() {
    if (widget.item.additionalData != null) {
      // First try to get the raw data
      final rawData = widget.item.additionalData!['raw_data'] as String?;
      if (rawData != null) {
        return rawData;
      }

      // Fallback to reconstructing the data
      switch (widget.item.title.toLowerCase()) {
        case 'sms qr code':
          final phone = widget.item.additionalData!['phone'] as String?;
          final message = widget.item.additionalData!['message'] as String?;
          if (phone != null) {
            return 'SMSTO:$phone${message != null ? ':$message' : ''}';
          }
          break;
        case 'email qr code':
          final email = widget.item.additionalData!['email'] as String?;
          final subject = widget.item.additionalData!['subject'] as String?;
          final body = widget.item.additionalData!['body'] as String?;
          if (email != null) {
            String mailtoData = 'MAILTO:$email';
            if (subject != null || body != null) {
              mailtoData += '?';
              if (subject != null) {
                mailtoData += 'subject=${Uri.encodeComponent(subject)}';
              }
              if (body != null) {
                if (subject != null) mailtoData += '&';
                mailtoData += 'body=${Uri.encodeComponent(body)}';
              }
            }
            return mailtoData;
          }
          break;
        case 'contact qr code':
          final vCardData = StringBuffer();
          vCardData.writeln('BEGIN:VCARD');
          vCardData.writeln('VERSION:3.0');
          if (widget.item.additionalData!['name'] != null) {
            vCardData.writeln('FN:${widget.item.additionalData!['name']}');
          }
          if (widget.item.additionalData!['phone'] != null) {
            vCardData.writeln('TEL:${widget.item.additionalData!['phone']}');
          }
          if (widget.item.additionalData!['email'] != null) {
            vCardData.writeln('EMAIL:${widget.item.additionalData!['email']}');
          }
          if (widget.item.additionalData!['organization'] != null) {
            vCardData
                .writeln('ORG:${widget.item.additionalData!['organization']}');
          }
          if (widget.item.additionalData!['address'] != null) {
            vCardData.writeln('ADR:${widget.item.additionalData!['address']}');
          }
          vCardData.writeln('END:VCARD');
          return vCardData.toString();
      }
    }
    return widget.item.subtitle;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('Could not launch phone app');
    }
  }

  Future<void> _addToContacts() async {
    try {
      // Request contacts permission
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        _showError('Permission to access contacts denied');
        return;
      }

      // Clean phone number
      String? cleanPhone;
      if (_contactInfo['phone'] != null && _contactInfo['phone']!.isNotEmpty) {
        cleanPhone = _contactInfo['phone']!.replaceAll(RegExp(r'[^\d+]'), '');
        if (!cleanPhone.startsWith('+')) {
          cleanPhone = '+$cleanPhone';
        }
      }

      // Show contact form dialog
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Contact'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Name'),
                    subtitle: Text(_contactInfo['name'] ?? ''),
                  ),
                  if (cleanPhone != null)
                    ListTile(
                      leading: Icon(Icons.phone),
                      title: Text('Phone'),
                      subtitle: Text(cleanPhone),
                    ),
                  if (_contactInfo['email'] != null)
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Email'),
                      subtitle: Text(_contactInfo['email']!),
                    ),
                  if (_contactInfo['organization'] != null)
                    ListTile(
                      leading: Icon(Icons.business),
                      title: Text('Organization'),
                      subtitle: Text(_contactInfo['organization']!),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final Contact newContact = Contact(
                      givenName: _contactInfo['name'],
                      phones:
                          cleanPhone != null ? [Item(value: cleanPhone)] : null,
                      emails: _contactInfo['email'] != null
                          ? [Item(value: _contactInfo['email'])]
                          : null,
                      company: _contactInfo['organization'],
                    );

                    await ContactsService.addContact(newContact);
                    if (!mounted) return;

                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contact added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('Error saving contact: $e');
                    Navigator.pop(context); // Close dialog
                    _showError('Failed to save contact. Please try again.');
                  }
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Contact add error: $e');
      _showError('Could not add contact. Please try again.');
    }
  }

  Future<void> _sendSMS() async {
    final phone = _smsInfo['phone'];
    final message = _smsInfo['message'];
    if (phone != null) {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phone,
        queryParameters: message != null ? {'body': message} : null,
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showError('Could not launch SMS app');
      }
    }
  }

  Future<void> _sendEmail() async {
    if (!isEmail) return;

    final Uri emailUri = Uri.parse(_getQRData());
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        _showError('Could not launch email app');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildQrPreview() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RepaintBoundary(
                key: qrKey,
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: QrImageView(
                    data: _getQRData(),
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryColor,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primaryColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primaryColor,
                    ),
                    padding: EdgeInsets.zero,
                    gapless: true,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            widget.item.type == 'scanned'
                ? 'Scanned QR Code'
                : 'Created QR Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.item.title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlPreview() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.language,
              color: AppColors.primaryColor,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'URL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _getQRData(),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSMSPreview() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.message,
                  color: AppColors.primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_smsInfo['phone'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        _smsInfo['phone']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_smsInfo['message'] != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _smsInfo['message']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailPreview() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email,
                  color: AppColors.primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_emailInfo['email'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        _emailInfo['email']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_emailInfo['subject'] != null) ...[
            SizedBox(height: 16),
            Text(
              'Subject:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _emailInfo['subject']!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
          if (_emailInfo['body'] != null) ...[
            SizedBox(height: 16),
            Text(
              'Message:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _emailInfo['body']!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactPreview() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.purple[700],
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_contactInfo['name'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        _contactInfo['name']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_contactInfo['phone'] != null)
            _buildContactDetail(Icons.phone, 'Phone', _contactInfo['phone']!),
          if (_contactInfo['email'] != null)
            _buildContactDetail(Icons.email, 'Email', _contactInfo['email']!),
          if (_contactInfo['organization'] != null)
            _buildContactDetail(
                Icons.business, 'Organization', _contactInfo['organization']!),
          if (_contactInfo['address'] != null)
            _buildContactDetail(
                Icons.location_on, 'Address', _contactInfo['address']!),
          if (_contactInfo['note'] != null)
            _buildContactDetail(Icons.note, 'Note', _contactInfo['note']!),
        ],
      ),
    );
  }

  Widget _buildContactDetail(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          widget.item.title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isUrl) _buildUrlPreview(),
                    if (isVCard) _buildContactPreview(),
                    if (isSMS) _buildSMSPreview(),
                    if (isEmail) _buildEmailPreview(),
                    _buildQrPreview(),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isVCard && _contactInfo['phone'] != null) ...[
                        _buildActionButton(
                          Icons.call,
                          'Call',
                          () => _makePhoneCall(_contactInfo['phone']!),
                        ),
                        _buildActionButton(
                          Icons.person_add,
                          'Add Contact',
                          _addToContacts,
                        ),
                      ],
                      if (isSMS && _smsInfo['phone'] != null)
                        _buildActionButton(
                          Icons.message,
                          'Send SMS',
                          _sendSMS,
                        ),
                      if (isEmail)
                        _buildActionButton(
                          Icons.email,
                          'Send Email',
                          _sendEmail,
                        ),
                      if (!isVCard && !isSMS && !isEmail && isUrl)
                        _buildActionButton(
                          Icons.open_in_new,
                          'Open',
                          () async {
                            final url = Uri.parse(_getQRData());
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                      _buildActionButton(
                        Icons.copy,
                        'Copy',
                        () {
                          Clipboard.setData(ClipboardData(text: _getQRData()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: EdgeInsets.all(16),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        Icons.share,
                        'Share',
                        () => Share.share(_getQRData()),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await QRSaverHelper.saveQRImage(
                            context, qrKey, 'qr_detail');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
