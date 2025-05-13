import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/qr_history_helper.dart';

class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '';
  String organization = '';
  String address = '';
  String phone = '';
  String email = '';
  String note = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.person, color: Colors.red, size: 40),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Contact',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 32),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  onSaved: (value) => fullName = value ?? '',
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Organization',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSaved: (value) => organization = value ?? '',
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSaved: (value) => address = value ?? '',
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                  onSaved: (value) => phone = value ?? '',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSaved: (value) => email = value ?? '',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Note',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSaved: (value) => note = value ?? '',
                  maxLines: 3,
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactResultScreen(
                              fullName: fullName,
                              organization: organization,
                              address: address,
                              phone: phone,
                              email: email,
                              note: note,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Create',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactResultScreen extends StatefulWidget {
  final String fullName;
  final String organization;
  final String address;
  final String phone;
  final String email;
  final String note;

  const ContactResultScreen({
    Key? key,
    required this.fullName,
    required this.organization,
    required this.address,
    required this.phone,
    required this.email,
    required this.note,
  }) : super(key: key);

  @override
  _ContactResultScreenState createState() => _ContactResultScreenState();
}

class _ContactResultScreenState extends State<ContactResultScreen> {
  String get vCardData {
    return '''BEGIN:VCARD
VERSION:3.0
FN:${widget.fullName}
TEL:${widget.phone}
EMAIL:${widget.email}
ADR:;;${widget.address};;;
ORG:${widget.organization}
TITLE:${widget.note}
END:VCARD''';
  }

  @override
  void initState() {
    super.initState();
    QRHistoryHelper.saveQRToHistoryAfterBuild(
      context,
      title: 'Contact',
      content: widget.fullName,
      iconPath: 'assets/icons/contact.png',
      additionalData: {
        'name': widget.fullName,
        'phone': widget.phone,
        'email': widget.email,
        'address': widget.address,
        'company': widget.organization,
        'title': widget.note,
      },
    );
  }

  Future<void> _saveQRImage(BuildContext context, String qrData) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/qr_code.png');

    // Save QR code implementation here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.person, color: Colors.red, size: 40),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Contact',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'QR has been Created',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: vCardData,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'Save QR Image',
                    onTap: () => _saveQRImage(context, vCardData),
                  ),
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'Share QR Code',
                    onTap: () => Share.share(vCardData),
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share Text',
                    onTap: () => Share.share(vCardData),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${widget.fullName}'),
                    if (widget.phone.isNotEmpty)
                      Text('Phone Number: ${widget.phone}'),
                    if (widget.email.isNotEmpty) Text('Email: ${widget.email}'),
                    if (widget.address.isNotEmpty)
                      Text('Address: ${widget.address}'),
                    if (widget.organization.isNotEmpty)
                      Text('Company: ${widget.organization}'),
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
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
