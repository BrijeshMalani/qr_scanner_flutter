import 'package:flutter/material.dart';
import '../utils/qr_history_helper.dart';

class HistoryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? iconPath;
  final String timestamp;
  final VoidCallback? onMoreTap;

  const HistoryItem({
    Key? key,
    required this.title,
    required this.subtitle,
    this.iconPath,
    required this.timestamp,
    this.onMoreTap,
  }) : super(key: key);

  Widget _buildIcon() {
    // If iconPath is 'material_icon' or null, use Material Icons
    if (iconPath == null || iconPath == 'material_icon') {
      final IconData icon = QRHistoryHelper.getIcon(title);
      final Color color = QRHistoryHelper.getIconColor(title);
      final Color backgroundColor = color.withOpacity(0.1);

      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      );
    }

    // For social media and other custom icons, try to use the image asset
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        iconPath!,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to material icon if image fails to load
          final IconData icon = QRHistoryHelper.getIcon(title);
          final Color color = QRHistoryHelper.getIconColor(title);
          return Icon(icon, color: color);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildIcon(),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            timestamp,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: onMoreTap,
        color: Colors.red,
      ),
    );
  }
}
