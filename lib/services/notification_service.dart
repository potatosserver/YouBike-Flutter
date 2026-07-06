import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum NotificationType { info, success, error }

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  void show({
    required String message,
    NotificationType type = NotificationType.info,
  }) {
    // WalkGo Style: 100% Native. 
    // Do not specify colors to let the Android OS handle the system theme.
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      fontSize: 14.0,
    );
    
    debugPrint("[Notification] [${type.name.toUpperCase()}] $message");
  }
}
