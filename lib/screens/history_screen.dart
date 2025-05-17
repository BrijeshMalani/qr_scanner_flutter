import 'package:flutter/material.dart';
import '../widgets/history_item.dart' as widget;
import '../models/history_item.dart';
import '../services/history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './qr_detail_screen.dart';
import './features/barcode_result_screen.dart';
import '../utils/qr_history_helper.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HistoryService _historyService;
  List<HistoryItem> scannedItems = [];
  List<HistoryItem> createdItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeHistory();
  }

  Future<void> _initializeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _historyService = HistoryService(prefs);
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      scannedItems = _historyService.getItems('scanned');
      createdItems = _historyService.getItems('created');
    });
  }

  void _navigateToDetail(BuildContext context, HistoryItem item) {
    if (item.title.startsWith('Barcode :')) {
      // Handle barcode items
      final type = item.additionalData?['type'] as String? ?? 'Code 128';
      final content =
          item.additionalData?['content'] as String? ?? item.subtitle;
      final error = item.additionalData?['error'] as String?;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeResultScreen(
            content: content,
            type: type,
          ),
        ),
      );
    } else {
      // Handle QR code items
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRDetailScreen(item: item),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'History',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              child: Text(
                'Scanned',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Tab(
              child: Text(
                'Created',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryList(scannedItems),
          _buildHistoryList(createdItems),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<HistoryItem> items) {
    return items.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'No History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your scanned items will appear here',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: items.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = items[index];
              final bool isBarcode = item.title.startsWith('Barcode :');
              final bool isSocialMedia =
                  item.title.toLowerCase().contains('twitter') ||
                      item.title.toLowerCase().contains('instagram') ||
                      item.title.toLowerCase().contains('facebook') ||
                      item.title.toLowerCase().contains('whatsapp') ||
                      item.title.toLowerCase().contains('youtube') ||
                      item.title.toLowerCase().contains('spotify');

              Widget leadingWidget;
              if (isBarcode) {
                leadingWidget = Icon(
                  Icons.qr_code_scanner,
                  color: Colors.indigo,
                );
              } else if (isSocialMedia) {
                String iconPath = 'assets/icons/';
                if (item.title.toLowerCase().contains('twitter')) {
                  iconPath += 'twitter.png';
                } else if (item.title.toLowerCase().contains('instagram')) {
                  iconPath += 'instagram.png';
                } else if (item.title.toLowerCase().contains('facebook')) {
                  iconPath += 'facebook.png';
                } else if (item.title.toLowerCase().contains('whatsapp')) {
                  iconPath += 'whatsapp.png';
                } else if (item.title.toLowerCase().contains('youtube')) {
                  iconPath += 'youtube.png';
                } else if (item.title.toLowerCase().contains('spotify')) {
                  iconPath += 'spotify.png';
                }
                leadingWidget = Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                );
              } else {
                leadingWidget = Icon(
                  QRHistoryHelper.getIcon(item.title),
                  color: QRHistoryHelper.getIconColor(item.title),
                );
              }

              final bool hasError =
                  isBarcode && item.additionalData?['error'] != null;

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Theme.of(context).cardColor,
                child: InkWell(
                  onTap: () => _navigateToDetail(context, item),
                  onLongPress: () =>
                      _showDeleteDialog(context, item, index, items),
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasError
                                ? Colors.red.withOpacity(0.1)
                                : (isBarcode
                                        ? Colors.indigo
                                        : QRHistoryHelper.getIconColor(
                                            item.title))
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: leadingWidget,
                        ),
                        title: Text(
                          isBarcode
                              ? (item.additionalData?['type'] as String? ??
                                  'Barcode')
                              : item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasError
                                ? Colors.red
                                : Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                            if (hasError)
                              Text(
                                item.additionalData?['error'] as String? ??
                                    'Error',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[300],
                              ),
                              onPressed: () => _showDeleteDialog(
                                  context, item, index, items),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  void _showDeleteDialog(BuildContext context, HistoryItem item, int index,
      List<HistoryItem> items) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Delete History Item'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(item, index, items);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(HistoryItem item, int index, List<HistoryItem> items) {
    setState(() {
      items.removeAt(index);
      _historyService.deleteItem(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              items.insert(index, item);
              _historyService.addItem(item);
            });
          },
        ),
      ),
    );
  }
}
