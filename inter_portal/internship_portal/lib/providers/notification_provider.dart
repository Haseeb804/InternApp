import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotificationProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _notifications = [];
  bool _hasUnread = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get hasUnread => _hasUnread;

  void addNotification(String title, String message, {String? type, String? action}) {
    _notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': title,
      'message': message,
      'type': type,
      'action': action,
      'timestamp': DateTime.now(),
      'read': false,
    });
    _hasUnread = true;
    notifyListeners();
  }

  void markAsRead(int id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['read'] = true;
      _updateUnreadStatus();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['read'] = true;
    }
    _hasUnread = false;
    notifyListeners();
  }

  void _updateUnreadStatus() {
    _hasUnread = _notifications.any((n) => !n['read']);
  }

  void clear() {
    _notifications.clear();
    _hasUnread = false;
    notifyListeners();
  }
}
