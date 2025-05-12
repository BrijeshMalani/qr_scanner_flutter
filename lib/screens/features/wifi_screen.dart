import 'package:flutter/material.dart';
import 'wifi_result_screen.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({Key? key}) : super(key: key);

  @override
  _WifiScreenState createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  String _encryptionType = 'WPA/WPA2';
  bool _isHidden = false;

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
          'Wifi',
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
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.wifi,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Wifi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _ssidController,
                decoration: InputDecoration(
                  labelText: 'SSID/Network',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('WPA/WPS2'),
                      leading: Radio(
                        value: 'WPA/WPA2',
                        groupValue: _encryptionType,
                        onChanged: (value) {
                          setState(() {
                            _encryptionType = value.toString();
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('WEP'),
                      leading: Radio(
                        value: 'WEP',
                        groupValue: _encryptionType,
                        onChanged: (value) {
                          setState(() {
                            _encryptionType = value.toString();
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('No password'),
                      leading: Radio(
                        value: 'nopass',
                        groupValue: _encryptionType,
                        onChanged: (value) {
                          setState(() {
                            _encryptionType = value.toString();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text('Hidden Network'),
                  trailing: Text(_isHidden ? 'Yes' : 'No'),
                  leading: Checkbox(
                    value: _isHidden,
                    onChanged: (value) {
                      setState(() {
                        _isHidden = value ?? false;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_ssidController.text.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WifiResultScreen(
                            ssid: _ssidController.text,
                            password: _passwordController.text,
                            encryptionType: _encryptionType,
                            isHidden: _isHidden,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
