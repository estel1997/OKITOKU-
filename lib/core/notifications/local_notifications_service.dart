import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 端末ローカル通知（価格ウォッチの確認など）。Android / iOS / macOS のみ初期化する。
abstract final class LocalNotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static bool _supportsLocalNotifications() {
    if (kIsWeb) {
      return false;
    }
    final p = defaultTargetPlatform;
    return p == TargetPlatform.android ||
        p == TargetPlatform.iOS ||
        p == TargetPlatform.macOS;
  }

  static Future<void> ensureInitialized() async {
    if (!_supportsLocalNotifications() || _initialized) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<void> _requestPlatformPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// ウォッチ ON 時のフィードバック。権限プロンプトの後に 1 件表示（拒否時は表示されない場合あり）。
  static Future<void> showWatchListAdded(String productName) async {
    if (!_supportsLocalNotifications()) {
      return;
    }
    await ensureInitialized();
    await _requestPlatformPermissions();

    const channelId = 'price_watch';
    const channelName = '価格ウォッチ';
    const channelDesc = 'ウォッチリストへの追加・価格低下（データ連携後に拡張）';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(2000000000);

    await _plugin.show(
      id: notificationId,
      title: '価格ウォッチ',
      body: '「$productName」をウォッチに追加しました',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
    );
  }
}
