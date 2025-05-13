import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = false;
  bool _vibrateEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('General'),
            _buildSettingItem(
              'Sound',
              Icons.volume_up,
              Colors.green,
              _soundEnabled,
              (value) => setState(() => _soundEnabled = value),
            ),
            _buildSettingItem(
              'Dark Theme',
              Icons.dark_mode,
              Colors.amber,
              isDark,
              (value) => themeProvider.toggleTheme(),
            ),
            _buildSettingItem(
              'Vibrate',
              Icons.vibration,
              Colors.blue,
              _vibrateEnabled,
              (value) => setState(() => _vibrateEnabled = value),
            ),
            _buildSettingItemWithArrow(
              'Language',
              Icons.language,
              Colors.orange,
              'English',
              () {},
            ),
            SizedBox(height: 24),
            _buildSectionTitle('Other'),
            _buildActionItem(
              'Rate us',
              Icons.thumb_up,
              Colors.green,
              () {},
            ),
            _buildActionItem(
              'Share',
              Icons.share,
              Colors.amber,
              () {},
            ),
            _buildActionItem(
              'Privacy Policy',
              Icons.privacy_tip,
              Colors.orange,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSettingItemWithArrow(
    String title,
    IconData icon,
    Color color,
    String value,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      onTap: onTap,
    );
  }
}
