import 'package:flutter/material.dart';
import 'history_service.dart';

class ServiceProvider extends InheritedWidget {
  final HistoryService historyService;

  const ServiceProvider({
    Key? key,
    required this.historyService,
    required Widget child,
  }) : super(key: key, child: child);

  static ServiceProvider of(BuildContext context) {
    final ServiceProvider? result =
        context.dependOnInheritedWidgetOfExactType<ServiceProvider>();
    assert(result != null, 'No ServiceProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ServiceProvider oldWidget) {
    return historyService != oldWidget.historyService;
  }
}
