import 'package:flutter/material.dart';
import 'features/location_screen.dart';
import 'features/notes_screen.dart';
import 'features/wifi_screen.dart';
import 'features/event_screen.dart';
import 'features/url_screen.dart';
import 'features/paypal_screen.dart';
import 'features/barcode_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget _buildFeatureItem(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
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
        title: Text(
          'Create QR Code',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              padding: EdgeInsets.all(8),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildFeatureItem(
                  Icons.location_on,
                  'Location',
                  Colors.amber,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LocationScreen()),
                  ),
                ),
                _buildFeatureItem(
                  Icons.note_alt,
                  'Notes',
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotesScreen()),
                  ),
                ),
                _buildFeatureItem(
                  Icons.wifi,
                  'Wifi',
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WifiScreen()),
                  ),
                ),
                _buildFeatureItem(
                  Icons.calendar_today,
                  'Event',
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventScreen()),
                  ),
                ),
                _buildFeatureItem(
                  Icons.language,
                  'URL',
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UrlScreen()),
                  ),
                ),
                _buildFeatureItem(
                  Icons.payment,
                  'Paypal',
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaypalScreen()),
                  ),
                ),
                _buildFeatureItem(
                  Icons.qr_code,
                  'Barcode',
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BarcodeScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
