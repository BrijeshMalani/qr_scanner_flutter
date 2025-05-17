import 'package:flutter/material.dart';
import 'contact_screen.dart';
import 'email_screen.dart';
import 'features/location_screen.dart';
import 'features/notes_screen.dart';
import 'features/wifi_screen.dart';
import 'features/event_screen.dart';
import 'features/url_screen.dart';
import 'features/paypal_screen.dart';
import 'features/barcode_screen.dart';
import '../utils/colors.dart';
import 'sms_screen.dart';
import 'social/instagram_screen.dart';
import 'social/spotify_screen.dart';
import 'social/facebook_screen.dart';
import 'social/whatsapp_screen.dart';
import 'social/youtube_screen.dart';
import 'social/twitter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialItem(String title, String imagePath, Color color) {
    return InkWell(
      onTap: () {
        switch (title) {
          case 'Twitter':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TwitterScreen()),
            );
            break;
          case 'Instagram':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InstagramScreen()),
            );
            break;
          case 'Facebook':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FacebookScreen()),
            );
            break;
          case 'WhatsApp':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WhatsAppScreen()),
            );
            break;
          case 'Youtube':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => YouTubeScreen()),
            );
            break;
          case 'Spotify':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SpotifyScreen()),
            );
            break;
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItem(
      String title, String subtitle, IconData icon, Color backgroundColor) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: backgroundColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'QR & Barcode Scanner',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ContactScreen()),
                            );
                          },
                          child: _buildPopularItem(
                            'Share Contact',
                            'Share your contact info',
                            Icons.person,
                            Colors.pink,
                          ),
                        ),
                        const SizedBox(width: 14),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SMSScreen()),
                            );
                          },
                          child: _buildPopularItem(
                            'Send SMS',
                            'Send SMS Message Anytime',
                            Icons.message,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EmailScreen()),
                            );
                          },
                          child: _buildPopularItem(
                            'Send Email',
                            'Send Email AddressAnytime',
                            Icons.email,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Social Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Social',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildSocialItem(
                          'Twitter', 'assets/icons/twitter.png', Colors.blue),
                      _buildSocialItem('Instagram',
                          'assets/icons/instagram.png', Colors.pink),
                      _buildSocialItem(
                          'Facebook', 'assets/icons/facebook.png', Colors.blue),
                      _buildSocialItem('WhatsApp', 'assets/icons/whatsapp.png',
                          Colors.green),
                      _buildSocialItem(
                          'Youtube', 'assets/icons/youtube.png', Colors.red),
                      _buildSocialItem(
                          'Spotify', 'assets/icons/spotify.png', Colors.green),
                    ],
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
