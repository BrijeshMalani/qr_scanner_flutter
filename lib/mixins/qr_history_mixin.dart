import 'package:flutter/material.dart';
import '../models/history_item.dart';
import '../services/service_provider.dart';

mixin QRHistoryMixin<T extends StatefulWidget> on State<T> {
  Future<void> saveToHistory(String title, String content,
      {String? iconPath}) async {
    final historyService = ServiceProvider.of(context).historyService;
    final historyItem = HistoryItem(
      type: 'created',
      title: title,
      subtitle: content,
      date: DateTime.now().toString(),
      iconPath: iconPath ?? 'assets/icons/qr_code.png',
    );
    await historyService.addItem(historyItem);
  }
}
