import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/history_item.dart';
import '../utils/qr_history_helper.dart';

class QRDetailScreen extends StatefulWidget {
  final HistoryItem item;

  const QRDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<QRDetailScreen> createState() => _QRDetailScreenState();
}

class _QRDetailScreenState extends State<QRDetailScreen> {
  String _getQRData() {
    final data = widget.item.subtitle;
    switch (widget.item.title.toLowerCase()) {
      case 'email':
        if (data.startsWith('MAILTO:')) {
          return data;
        }
        // Parse email data if it's not in MAILTO format
        final emailParts = data.split('\n');
        String email = '', subject = '', body = '';
        for (var part in emailParts) {
          if (part.startsWith('Email:')) {
            email = part.substring(6).trim();
          } else if (part.startsWith('Subject:')) {
            subject = part.substring(8).trim();
          } else if (part.startsWith('Body:')) {
            body = part.substring(5).trim();
          }
        }
        String mailtoData = 'MAILTO:$email';
        if (subject.isNotEmpty || body.isNotEmpty) {
          mailtoData += '?';
          if (subject.isNotEmpty) {
            mailtoData += 'subject=${Uri.encodeComponent(subject)}';
          }
          if (body.isNotEmpty) {
            if (subject.isNotEmpty) mailtoData += '&';
            mailtoData += 'body=${Uri.encodeComponent(body)}';
          }
        }
        return mailtoData;

      case 'sms':
        if (data.startsWith('SMSTO:')) {
          return data;
        }
        // Parse SMS data if it's not in SMSTO format
        final smsParts = data.split('\n');
        String phone = '', message = '';
        for (var part in smsParts) {
          if (part.startsWith('Phone:')) {
            phone = part.substring(6).trim();
          } else if (part.startsWith('Message:')) {
            message = part.substring(8).trim();
          }
        }
        return 'SMSTO:$phone:$message';

      case 'contact':
        if (data.startsWith('BEGIN:VCARD')) {
          return data;
        }
        // Parse contact data if it's not in vCard format
        final contactParts = data.split('\n');
        String name = '',
            phone = '',
            email = '',
            org = '',
            title = '',
            address = '';
        for (var part in contactParts) {
          if (part.startsWith('Name:')) {
            name = part.substring(5).trim();
          } else if (part.startsWith('Phone:')) {
            phone = part.substring(6).trim();
          } else if (part.startsWith('Email:')) {
            email = part.substring(6).trim();
          } else if (part.startsWith('Organization:')) {
            org = part.substring(13).trim();
          } else if (part.startsWith('Title:')) {
            title = part.substring(6).trim();
          } else if (part.startsWith('Address:')) {
            address = part.substring(8).trim();
          }
        }
        return '''BEGIN:VCARD
VERSION:3.0
FN:$name
TEL:$phone
EMAIL:$email
ADR:;;$address;;;
ORG:$org
TITLE:$title
END:VCARD''';

      case 'url':
        if (data.startsWith('http://') || data.startsWith('https://')) {
          return data;
        }
        return 'https://$data';

      case 'wifi':
        if (data.startsWith('WIFI:')) {
          return data;
        }
        // Parse WiFi data if it's not in WIFI format
        final wifiParts = data.split('\n');
        String ssid = '', password = '', security = 'WPA';
        for (var part in wifiParts) {
          if (part.startsWith('SSID:')) {
            ssid = part.substring(5).trim();
          } else if (part.startsWith('Password:')) {
            password = part.substring(9).trim();
          } else if (part.startsWith('Security:')) {
            security = part.substring(9).trim();
          }
        }
        return 'WIFI:S:$ssid;T:$security;P:$password;;';

      default:
        return data;
    }
  }

  Widget _buildQRImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: QrImageView(
          data: _getQRData(),
          version: QrVersions.auto,
          size: 200,
          backgroundColor: Colors.white,
          padding: EdgeInsets.all(16),
          errorStateBuilder: (context, error) {
            return Center(
              child: Icon(
                Icons.qr_code_2,
                size: 100,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeSpecificContent(BuildContext context) {
    final data = widget.item.subtitle;
    Map<String, dynamic> parsedData = {};

    switch (widget.item.type.toLowerCase()) {
      case 'email':
        if (data.startsWith('MAILTO:')) {
          final uri = Uri.parse(data);
          parsedData = {
            'email': uri.path,
            'subject': uri.queryParameters['subject'] ?? '',
            'body': uri.queryParameters['body'] ?? '',
          };
        } else {
          final emailParts = data.split('\n');
          for (var part in emailParts) {
            if (part.startsWith('Email:')) {
              parsedData['email'] = part.substring(6).trim();
            } else if (part.startsWith('Subject:')) {
              parsedData['subject'] = part.substring(8).trim();
            } else if (part.startsWith('Body:')) {
              parsedData['body'] = part.substring(5).trim();
            }
          }
        }
        return _buildEmailContent(context, parsedData);

      case 'sms':
        if (data.startsWith('SMSTO:')) {
          final parts = data.substring(6).split(':');
          parsedData = {
            'phone': parts[0],
            'message': parts.length > 1 ? parts[1] : '',
          };
        } else {
          final smsParts = data.split('\n');
          for (var part in smsParts) {
            if (part.startsWith('Phone:')) {
              parsedData['phone'] = part.substring(6).trim();
            } else if (part.startsWith('Message:')) {
              parsedData['message'] = part.substring(8).trim();
            }
          }
        }
        return _buildSMSContent(context, parsedData);

      case 'contact':
        if (data.startsWith('BEGIN:VCARD')) {
          final lines = data.split('\n');
          for (var line in lines) {
            if (line.startsWith('FN:')) {
              parsedData['name'] = line.substring(3).trim();
            } else if (line.startsWith('TEL:')) {
              parsedData['phone'] = line.substring(4).trim();
            } else if (line.startsWith('EMAIL:')) {
              parsedData['email'] = line.substring(6).trim();
            } else if (line.startsWith('ORG:')) {
              parsedData['organization'] = line.substring(4).trim();
            } else if (line.startsWith('TITLE:')) {
              parsedData['note'] = line.substring(6).trim();
            } else if (line.startsWith('ADR:')) {
              parsedData['address'] = line
                  .substring(4)
                  .split(';')
                  .where((s) => s.isNotEmpty)
                  .join(', ');
            }
          }
        } else {
          final contactParts = data.split('\n');
          for (var part in contactParts) {
            if (part.startsWith('Name:')) {
              parsedData['name'] = part.substring(5).trim();
            } else if (part.startsWith('Phone:')) {
              parsedData['phone'] = part.substring(6).trim();
            } else if (part.startsWith('Email:')) {
              parsedData['email'] = part.substring(6).trim();
            } else if (part.startsWith('Organization:')) {
              parsedData['organization'] = part.substring(13).trim();
            }
          }
        }
        return _buildContactContent(context, parsedData);

      case 'url':
        return _buildUrlContent(context);

      default:
        return _buildDefaultContent(context);
    }
  }

  Widget _buildEmailContent(BuildContext context, Map<String, dynamic> email) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.email, color: Colors.blue),
          ),
          title: Text('Email'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To: ${email['email'] ?? ''}'),
              if (email['subject'] != null && email['subject']!.isNotEmpty)
                Text('Subject: ${email['subject']}'),
              if (email['body'] != null && email['body']!.isNotEmpty)
                Text('Message: ${email['body']}',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text('Send Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _launchEmail(email),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSMSContent(BuildContext context, Map<String, dynamic> sms) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.message, color: Colors.green),
          ),
          title: Text('SMS Message'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To: ${sms['phone'] ?? ''}'),
              if (sms['message'] != null && sms['message']!.isNotEmpty)
                Text('Message: ${sms['message']}',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.message),
                  label: Text('Send SMS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _launchSMS(sms),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactContent(
      BuildContext context, Map<String, dynamic> contact) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person, color: Colors.purple),
          ),
          title: Text(contact['name'] ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact['phone'] != null && contact['phone']!.isNotEmpty)
                Text('Phone: ${contact['phone']}'),
              if (contact['email'] != null && contact['email']!.isNotEmpty)
                Text('Email: ${contact['email']}'),
              if (contact['organization'] != null &&
                  contact['organization']!.isNotEmpty)
                Text('Organization: ${contact['organization']}'),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (contact['phone'] != null && contact['phone']!.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.call),
                    label: Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _makePhoneCall(contact['phone']!),
                  ),
                ),
              if (contact['phone'] != null && contact['phone']!.isNotEmpty)
                SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.person_add),
                  label: Text('Add Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _addToContacts(contact),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrlContent(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.link),
          title: Text('URL'),
          subtitle: Text(widget.item.subtitle),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.open_in_browser),
              label: Text('Open'),
              onPressed: () => _launchUrl(widget.item.subtitle),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.copy),
              label: Text('Copy'),
              onPressed: () => _copyToClipboard(context, widget.item.subtitle),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.share),
              label: Text('Share'),
              onPressed: () => _shareContent(widget.item.subtitle),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.data_object),
          title: Text(widget.item.title),
          subtitle: Text(widget.item.subtitle),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.copy),
              label: Text('Copy'),
              onPressed: () => _copyToClipboard(context, widget.item.subtitle),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.share),
              label: Text('Share'),
              onPressed: () => _shareContent(widget.item.subtitle),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _shareContent(String content) async {
    await Share.share(content);
  }

  Future<void> _addToContacts(Map<String, dynamic> contact) async {
    final permission = await Permission.contacts.request();
    if (permission.isGranted) {
      try {
        final newContact = Contact(
          givenName: contact['name'],
          phones: [Item(label: 'mobile', value: contact['phone'])],
          emails: contact['email'] != null
              ? [Item(label: 'email', value: contact['email'])]
              : null,
        );
        await ContactsService.addContact(newContact);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Contact added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add contact')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission to access contacts denied')),
        );
      }
    }
  }

  Future<void> _launchEmail(Map<String, dynamic> email) async {
    final Uri emailUri = Uri.parse(_getQRData());
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch email app')),
        );
      }
    }
  }

  Future<void> _launchSMS(Map<String, dynamic> sms) async {
    final Uri smsUri = Uri.parse(
        'sms:${sms['phone']}${sms['message'] != null ? '?body=${Uri.encodeComponent(sms['message'])}' : ''}');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch messaging app')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text('QR Code Details'),
        foregroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildQRImage(),
              SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: _buildTypeSpecificContent(context),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Scanned on ${widget.item.date}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
