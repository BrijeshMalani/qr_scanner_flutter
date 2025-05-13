import 'package:flutter/material.dart';
import 'paypal_result_screen.dart';

class PaypalScreen extends StatefulWidget {
  const PaypalScreen({Key? key}) : super(key: key);

  @override
  _PaypalScreenState createState() => _PaypalScreenState();
}

class _PaypalScreenState extends State<PaypalScreen> {
  final _paypalController = TextEditingController();

  bool _isValidPaypalMe(String link) {
    if (link.isEmpty) return false;
    final paypalPattern = RegExp(
      r'^[a-zA-Z0-9@._-]+$',
    );
    return paypalPattern.hasMatch(link);
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
          'Paypal',
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
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.payment,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Paypal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _paypalController,
                decoration: InputDecoration(
                  labelText: 'Me Link',
                  hintText: 'your.name@paypal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    final paypalMe = _paypalController.text.trim();
                    if (_isValidPaypalMe(paypalMe)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayPalResultScreen(
                            paypalEmail: paypalMe,
                            amount: null,
                            currency: null,
                            note: null,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Please enter a valid PayPal.me username')),
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
                      color: Colors.white,
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
    _paypalController.dispose();
    super.dispose();
  }
}
