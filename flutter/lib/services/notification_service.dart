import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  Future<void> initialize(String appId) async {
    if (appId.isEmpty) return;
    OneSignal.initialize(appId);
  }

  Future<void> requestPermission() async {
    await OneSignal.Notifications.requestPermission(true);
  }

  void setExternalUserId(String userId) {
    OneSignal.login(userId);
  }

  void removeExternalUserId() {
    OneSignal.logout();
  }
}
