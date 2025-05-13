import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRHistoryHelper {
  static IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sms':
        return Icons.message;
      case 'email':
        return Icons.email;
      case 'contact':
      case 'contact qr code':
        return Icons.contact_phone;
      case 'barcode':
        return Icons.qr_code;
      case 'paypal':
      case 'paypal qr code':
        return Icons.payment;
      case 'url':
      case 'url qr code':
        return Icons.link;
      case 'wifi':
        return Icons.wifi;
      case 'location':
        return Icons.location_on;
      case 'notes':
        return Icons.note;
      case 'event':
        return Icons.event;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.chat;
      case 'whatsapp':
        return Icons.chat_bubble;
      case 'youtube':
        return Icons.play_circle_filled;
      case 'spotify':
        return Icons.music_note;
      default:
        return Icons.qr_code;
    }
  }

  static Color getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'sms':
        return Colors.blue;
      case 'email':
        return Colors.green;
      case 'contact':
      case 'contact qr code':
        return Colors.purple;
      case 'barcode':
        return Colors.indigo;
      case 'paypal':
      case 'paypal qr code':
        return Colors.blue;
      case 'url':
      case 'url qr code':
        return Colors.blue;
      case 'wifi':
        return Colors.red;
      case 'location':
        return Colors.amber;
      case 'notes':
        return Colors.green;
      case 'event':
        return Colors.purple;
      case 'instagram':
        return Colors.pink;
      case 'facebook':
        return Colors.blue;
      case 'twitter':
        return Colors.lightBlue;
      case 'whatsapp':
        return Colors.green;
      case 'youtube':
        return Colors.red;
      case 'spotify':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static void saveQRToHistoryAfterBuild(
    BuildContext context, {
    required String title,
    required String content,
    String? iconPath,
    Map<String, dynamic>? additionalData,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final historyService = HistoryService(prefs);

      final item = HistoryItem(
        title: title,
        subtitle: content,
        iconPath:
            iconPath ?? 'material_icon', // Special marker for material icons
        date: DateTime.now().toString(),
        type: 'created',
        additionalData: additionalData,
      );

      await historyService.addItem(item);
    });
  }
}
