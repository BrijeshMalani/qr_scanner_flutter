import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/qr_history_helper.dart';

class WhatsAppScreen extends StatefulWidget {
  @override
  _WhatsAppScreenState createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  final _formKey = GlobalKey<FormState>();
  String phoneNumber = '';

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
          'WhatsApp',
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
                      color: Color(0xFFE7FFE7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/icons/whatsapp.png',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'WhatsApp',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 32),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone Number (with country code)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                  onSaved: (value) => phoneNumber = value ?? '',
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
                            builder: (context) => WhatsAppResultScreen(
                              phoneNumber: phoneNumber,
                              message: '',
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

class WhatsAppResultScreen extends StatefulWidget {
  final String phoneNumber;
  final String message;

  const WhatsAppResultScreen({
    Key? key,
    required this.phoneNumber,
    required this.message,
  }) : super(key: key);

  @override
  _WhatsAppResultScreenState createState() => _WhatsAppResultScreenState();
}

class _WhatsAppResultScreenState extends State<WhatsAppResultScreen> {
  String get whatsappData =>
      'https://wa.me/${widget.phoneNumber}?text=${Uri.encodeComponent(widget.message)}';

  @override
  void initState() {
    super.initState();
    QRHistoryHelper.saveQRToHistoryAfterBuild(
      context,
      title: 'WhatsApp',
      content: 'Chat with: ${widget.phoneNumber}',
      iconPath: 'assets/icons/whatsapp.png',
      additionalData: {
        'phone': widget.phoneNumber,
        'message': widget.message,
      },
    );
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
                    color: Color(0xFFE7FFE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/icons/whatsapp.png',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Social',
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
                  data: whatsappData,
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
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: Icons.qr_code,
                    label: 'Share QR Code',
                    onTap: () => Share.share(whatsappData),
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share Text',
                    onTap: () => Share.share(whatsappData),
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
                child: SelectableText(
                  whatsappData,
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
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
