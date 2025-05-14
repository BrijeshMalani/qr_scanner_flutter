import 'package:flutter/material.dart';
import '../widgets/history_item.dart' as widget;
import '../models/history_item.dart';
import '../services/history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './qr_detail_screen.dart';
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
  List<HistoryItem> bcardItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      bcardItems = _historyService.getItems('bcard');
    });
  }

  void _navigateToDetail(BuildContext context, HistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRDetailScreen(item: item),
      ),
    );
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
                child: Text('Scanned',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Tab(
                child: Text('Created',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
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
              final IconData icon = QRHistoryHelper.getIcon(item.title);
              final Color iconColor = QRHistoryHelper.getIconColor(item.title);

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.iconPath != null &&
                            item.iconPath != 'material_icon'
                        ? Image.asset(
                            item.iconPath!,
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                color: iconColor,
                              );
                            },
                          )
                        : Icon(
                            icon,
                            color: iconColor,
                          ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onTap: () => _navigateToDetail(context, item),
                ),
              );
            },
          );
  }
}
