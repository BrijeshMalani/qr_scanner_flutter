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
    switch (widget.item.type.toLowerCase()) {
      case 'url':
        return widget.item.subtitle;
      case 'contact':
        final contact = widget.item.additionalData?['contact'] ?? {};
        return '''BEGIN:VCARD
VERSION:3.0
FN:${contact['name'] ?? ''}
TEL:${contact['phone'] ?? ''}
EMAIL:${contact['email'] ?? ''}
END:VCARD''';
      case 'wifi':
        final wifi = widget.item.additionalData?['wifi'] ?? {};
        return 'WIFI:S:${wifi['ssid']};T:${wifi['security']};P:${wifi['password']};;';
      case 'location':
        final location = widget.item.additionalData?['location'] ?? {};
        return 'geo:${location['latitude']},${location['longitude']}';
      default:
        return widget.item.subtitle;
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
    switch (widget.item.type.toLowerCase()) {
      case 'url':
        return _buildUrlContent(context);
      case 'text':
        return _buildTextContent(context);
      case 'contact':
        return _buildContactContent(context);
      case 'wifi':
        return _buildWifiContent(context);
      case 'location':
        return _buildLocationContent(context);
      default:
        return _buildDefaultContent(context);
    }
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

  Widget _buildTextContent(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.text_fields),
          title: Text('Text'),
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

  Widget _buildContactContent(BuildContext context) {
    final Map<String, dynamic> contact =
        widget.item.additionalData?['contact'] ?? {};
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.person),
          title: Text(contact['name'] ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact['phone'] != null) Text('Phone: ${contact['phone']}'),
              if (contact['email'] != null) Text('Email: ${contact['email']}'),
            ],
          ),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            if (contact['phone'] != null)
              ElevatedButton.icon(
                icon: Icon(Icons.call),
                label: Text('Call'),
                onPressed: () => _launchUrl('tel:${contact['phone']}'),
              ),
            if (contact['email'] != null)
              ElevatedButton.icon(
                icon: Icon(Icons.email),
                label: Text('Email'),
                onPressed: () => _launchUrl('mailto:${contact['email']}'),
              ),
            ElevatedButton.icon(
              icon: Icon(Icons.person_add),
              label: Text('Add Contact'),
              onPressed: () => _addToContacts(contact),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWifiContent(BuildContext context) {
    final Map<String, dynamic> wifi = widget.item.additionalData?['wifi'] ?? {};
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.wifi),
          title: Text(wifi['ssid'] ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Password: ${wifi['password'] ?? ''}'),
              Text('Security: ${wifi['security'] ?? 'None'}'),
            ],
          ),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.copy),
              label: Text('Copy Password'),
              onPressed: () =>
                  _copyToClipboard(context, wifi['password'] ?? ''),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.share),
              label: Text('Share'),
              onPressed: () => _shareContent(
                  'SSID: ${wifi['ssid']}\nPassword: ${wifi['password']}'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationContent(BuildContext context) {
    final Map<String, dynamic> location =
        widget.item.additionalData?['location'] ?? {};
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Location'),
          subtitle: Text('${location['latitude']}, ${location['longitude']}'),
        ),
        ButtonBar(
          alignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text('Open Maps'),
              onPressed: () =>
                  _openInMaps(location['latitude'], location['longitude']),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.copy),
              label: Text('Copy'),
              onPressed: () => _copyToClipboard(
                context,
                '${location['latitude']}, ${location['longitude']}',
              ),
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

  Future<void> _openInMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Details'),
        backgroundColor: Colors.white,
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
