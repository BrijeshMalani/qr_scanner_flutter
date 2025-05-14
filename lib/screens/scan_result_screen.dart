import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import '../services/service_provider.dart';
import '../models/history_item.dart';
import '../utils/colors.dart';

class ScanResultScreen extends StatefulWidget {
  final String scannedCode;
  final File? qrImage;

  const ScanResultScreen({
    Key? key,
    required this.scannedCode,
    this.qrImage,
  }) : super(key: key);

  @override
  _ScanResultScreenState createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool get isUrl => Uri.tryParse(widget.scannedCode)?.hasScheme ?? false;
  bool get isVCard => widget.scannedCode.trim().startsWith('BEGIN:VCARD');
  bool get isSMS => widget.scannedCode.trim().startsWith('SMSTO:');
  bool get isEmail => widget.scannedCode.trim().startsWith('MAILTO:');
  Map<String, String> _contactInfo = {};
  Map<String, String> _smsInfo = {};
  Map<String, String> _emailInfo = {};

  @override
  void initState() {
    super.initState();
    if (isVCard) {
      _parseVCard();
    } else if (isSMS) {
      _parseSMS();
    } else if (isEmail) {
      _parseEmail();
    }
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _saveToHistory();
    // });
  }

  void _parseVCard() {
    final lines = widget.scannedCode.split('\n');
    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        final key = parts[0].trim();
        final value = parts[1].trim();
        switch (key) {
          case 'FN':
            _contactInfo['name'] = value;
            break;
          case 'TEL':
            _contactInfo['phone'] = value;
            break;
          case 'EMAIL':
            _contactInfo['email'] = value;
            break;
          case 'ADR':
            final address =
                value.split(';').where((s) => s.isNotEmpty).join(', ');
            _contactInfo['address'] = address;
            break;
          case 'ORG':
            _contactInfo['organization'] = value;
            break;
          case 'TITLE':
            _contactInfo['note'] = value;
            break;
        }
      }
    }
  }

  void _parseSMS() {
    // Remove 'SMSTO:' prefix
    final content = widget.scannedCode.substring(6);
    final parts = content.split(':');
    if (parts.length >= 1) {
      _smsInfo['phone'] = parts[0];
      if (parts.length >= 2) {
        _smsInfo['message'] = parts[1];
      }
    }
  }

  void _parseEmail() {
    String content = widget.scannedCode.substring(7); // Remove 'MAILTO:'
    final Uri uri = Uri.parse('MAILTO:$content');

    _emailInfo['email'] = uri.path;

    if (uri.hasQuery) {
      final params = uri.queryParameters;
      if (params.containsKey('subject')) {
        _emailInfo['subject'] = Uri.decodeComponent(params['subject']!);
      }
      if (params.containsKey('body')) {
        _emailInfo['body'] = Uri.decodeComponent(params['body']!);
      }
    }
  }

  Future<void> _saveToHistory() async {
    final historyService = ServiceProvider.of(context).historyService;
    final historyItem = HistoryItem(
      type: 'scanned',
      title: _getContentType(),
      subtitle: _getSubtitle(),
      date: DateTime.now().toString(),
      iconPath: _getIconPath(),
      additionalData: isVCard
          ? _contactInfo
          : isSMS
              ? _smsInfo
              : isEmail
                  ? _emailInfo
                  : null,
    );
    await historyService.addItem(historyItem);
  }

  String _getContentType() {
    if (isUrl) return 'URL QR Code';
    if (isVCard) return 'Contact QR Code';
    if (isSMS) return 'SMS QR Code';
    if (isEmail) return 'Email QR Code';
    return 'Text QR Code';
  }

  String _getSubtitle() {
    if (isVCard) return _contactInfo['name'] ?? 'Unknown Contact';
    if (isSMS) return 'To: ${_smsInfo['phone'] ?? 'Unknown Number'}';
    if (isEmail) return 'To: ${_emailInfo['email'] ?? 'Unknown Email'}';
    return widget.scannedCode;
  }

  String _getIconPath() {
    if (isUrl) return 'assets/icons/url.png';
    if (isVCard) return 'assets/icons/contact.png';
    if (isSMS) return 'assets/icons/sms.png';
    if (isEmail) return 'assets/icons/email.png';
    return 'assets/icons/qr_code.png';
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
      final Contact newContact = Contact(
        givenName: _contactInfo['name'],
        phones: _contactInfo['phone'] != null
            ? [Item(label: "mobile", value: _contactInfo['phone'])]
            : null,
        emails: _contactInfo['email'] != null
            ? [Item(label: "work", value: _contactInfo['email'])]
            : null,
        company: _contactInfo['organization'],
        jobTitle: _contactInfo['note'],
      );

      await ContactsService.addContact(newContact);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showError('Error adding contact: $e');
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

    final Uri emailUri = Uri.parse(widget.scannedCode);
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
    _saveToHistory();
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
              child: widget.qrImage != null
                  ? Image.file(
                      widget.qrImage!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      padding: EdgeInsets.all(16),
                      child: QrImageView(
                        data: widget.scannedCode,
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
          SizedBox(height: 20),
          Text(
            'Scanned QR Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _getContentType(),
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
                  widget.scannedCode,
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
          _getContentType(),
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
                            final url = Uri.parse(widget.scannedCode);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                      _buildActionButton(
                        Icons.copy,
                        'Copy',
                        () {
                          Clipboard.setData(
                              ClipboardData(text: widget.scannedCode));
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
                        () => Share.share(widget.scannedCode),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement download functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Download started'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.all(16),
                          ),
                        );
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
}
