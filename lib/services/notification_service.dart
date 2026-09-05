import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null && details.payload!.isNotEmpty) {
          _handleNotificationTap(details.payload!);
        }
      },
    );
    _initialized = true;

    try {
      await Firebase.initializeApp();
      await _initFirebaseMessaging();
    } catch (_) {}

    try {
      await scheduleGratitudeNotifications();
    } catch (_) {}

    try {
      await scheduleDailyGameNotifications();
    } catch (_) {}
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      Future<void> fetchAndSendToken() async {
        try {
          if (Platform.isIOS) {
            await FirebaseMessaging.instance.getAPNSToken();
          }

          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await _sendTokenToServer(token);
          }
        } catch (_) {}
      }

      await fetchAndSendToken();

      Future.delayed(const Duration(seconds: 5), () {
        fetchAndSendToken();
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _sendTokenToServer(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showFCMForegroundNotification(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final clickUrl = message.data['click_url'] as String?;
        if (clickUrl != null && clickUrl.isNotEmpty) {
          _handleNotificationTap(clickUrl);
        }
      });

      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final clickUrl = initialMessage.data['click_url'] as String?;
        if (clickUrl != null && clickUrl.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            _handleNotificationTap(clickUrl);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final HttpClient client = HttpClient();
      final Uri uri = Uri.parse(
          'https://codego.io.vn/api/noiso_update_device_token.php');
      final HttpClientRequest request = await client.postUrl(uri);

      request.headers.set('content-type', 'application/json; charset=utf-8');

      final Map<String, dynamic> bodyMap = {
        'user_id': 0,
        'device_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android'
      };

      request.add(utf8.encode(json.encode(bodyMap)));
      final HttpClientResponse response = await request.close();
      await response.transform(utf8.decoder).join();
    } catch (_) {}
  }

  void _showFCMForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? 'Thông báo từ Nối Số Biển Sâu';
    final body = message.notification?.body ?? '';
    final clickUrl = message.data['click_url'] as String? ?? '';

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'noiso_fcm_messages',
      'Tin nhắn hệ thống',
      channelDescription: 'Hiển thị thông báo tin tức từ hệ thống',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
      payload: clickUrl,
    );
  }

  void _handleNotificationTap(String payload) {
    if (payload.startsWith('http') || payload.startsWith('https')) {
      try {
        final Uri url = Uri.parse(payload);
        launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  Future<bool> _isEnglishLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    if (savedLang != null) {
      return savedLang == 'en';
    }
    final locale = Platform.localeName.toLowerCase();
    return locale.startsWith('en');
  }

  Future<void> scheduleDailyGameNotifications() async {
    final now = DateTime.now();

    try {
      final isEn = await _isEnglishLanguage();

      final dynamicLevel = (now.day % 15) + 5;
      final dynamicBeatPercent = 85 + (now.day % 12);
      final dynamicBonus = (now.day % 8 + 3) * 50;

      final morningTarget = DateTime(now.year, now.month, now.day, 8, 30);
      var morningScheduled = tz.TZDateTime.from(morningTarget, tz.local);
      if (morningScheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        morningScheduled = morningScheduled.add(const Duration(days: 1));
      }

      final morningTitle = isEn
          ? 'Deep sea awakening: The dance of numbers! 🌊✨'
          : 'Đáy biển thức giấc: Vũ điệu của những con số! 🌊✨';
      final morningBody = isEn
          ? 'Start your day with dynamic energy at Level $dynamicLevel! $dynamicBeatPercent% of divers are ready, how about you? ❤️'
          : 'Mở đầu ngày mới tràn đầy năng lượng cùng Cấp $dynamicLevel! $dynamicBeatPercent% thợ lặn đã sẵn sàng, còn bạn thì sao? ❤️';

      await _plugin.zonedSchedule(
        6001,
        morningTitle,
        morningBody,
        morningScheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'noiso_morning_channel',
            'Morning Brain Challenge',
            channelDescription: 'Thông báo khởi động tư duy buổi sáng',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      final afternoonTarget = DateTime(now.year, now.month, now.day, 14, 0);
      var afternoonScheduled = tz.TZDateTime.from(afternoonTarget, tz.local);
      if (afternoonScheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        afternoonScheduled = afternoonScheduled.add(const Duration(days: 1));
      }

      final afternoonTitle = isEn
          ? 'Soothing waves beneath the blue ocean 🐟💙'
          : 'Làn sóng thư giãn dưới đại dương xanh 🐟💙';
      final afternoonBody = isEn
          ? 'Relax with gentle ocean waves this afternoon and claim +$dynamicBonus bonus energy points! 🌟'
          : 'Thả mình vào nhịp sóng êm dịu chiều nay và nhận ngay +$dynamicBonus điểm năng lượng ngọt ngào nhé! 🌟';

      await _plugin.zonedSchedule(
        6002,
        afternoonTitle,
        afternoonBody,
        afternoonScheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'noiso_afternoon_channel',
            'Afternoon Relaxation',
            channelDescription: 'Thông báo thư giãn trí não buổi chiều',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      final eveningTarget = DateTime(now.year, now.month, now.day, 19, 30);
      var eveningScheduled = tz.TZDateTime.from(eveningTarget, tz.local);
      if (eveningScheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        eveningScheduled = eveningScheduled.add(const Duration(days: 1));
      }

      final eveningTitle = isEn
          ? 'Night ocean secrets: Legend\'s glowing light! 🏆🌙'
          : 'Bí ẩn đại dương đêm: Ánh sáng của huyền thoại! 🏆🌙';
      final eveningBody = isEn
          ? 'The glowing night sea is calling for a new champion. Leave your mark on the leaderboard tonight! 🚀🔥'
          : 'Biển đêm rực rỡ đang gọi tên nhà vô địch mới. Hãy để lại dấu ấn kỷ lục đỉnh cao của bạn tối nay! 🚀🔥';

      await _plugin.zonedSchedule(
        6003,
        eveningTitle,
        eveningBody,
        eveningScheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'noiso_evening_channel',
            'Evening Leaderboard Challenge',
            channelDescription: 'Thông báo thách đấu kỷ lục buổi tối',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  Future<void> scheduleGratitudeNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final isScheduled = prefs.getBool('noiso_gratitude_scheduled') ?? false;
    if (isScheduled) {
      return;
    }

    final isEn = await _isEnglishLanguage();
    final mocs = [3, 5, 7, 9, 12, 15, 17, 19, 21];
    final now = DateTime.now();

    for (final moc in mocs) {
      final targetDate = now.add(Duration(days: moc));
      final scheduled = tz.TZDateTime.from(
        DateTime(targetDate.year, targetDate.month, targetDate.day, 20, 0),
        tz.local,
      );

      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        continue;
      }

      final title = isEn ? _getGratitudeTitleEn(moc) : _getGratitudeTitleVi(moc);
      final body = isEn ? _getGratitudeBodyEn(moc) : _getGratitudeBodyVi(moc);

      final notificationId = 7000 + moc;

      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gratitude_reminders',
            'Gratitude Reminders',
            channelDescription: 'Thông báo tri ân người dùng đồng hành cùng app',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    await prefs.setBool('noiso_gratitude_scheduled', true);
  }

  String _getGratitudeTitleVi(int moc) {
    switch (moc) {
      case 3:
        return '3 ngày thám hiểm: Lắng nghe tiếng gọi của biển! 🐬';
      case 5:
        return 'Nốt nhạc đại dương: Kết nối những niềm vui! 🌊';
      case 7:
        return 'Tròn một tuần: Dấu ấn của nhà thám hiểm! 🎉';
      case 9:
        return 'Kho báu ẩn giấu dưới đáy biển sâu 🐙';
      case 12:
        return 'Khoảnh khắc bình yên giữa đại dương 💎';
      case 15:
        return 'Nửa tháng kiên trì: Rực rỡ ánh hào quang! 📈';
      case 17:
        return 'Trái tim biển cả: Bản lĩnh của nhà vô địch! ✨';
      case 19:
        return 'Chuyến hải trình kỳ diệu chưa hồi kết 🎯';
      case 21:
        return '3 tuần tri ân: Gắn kết từ trái tim đại dương! 🏆';
      default:
        return 'Cảm ơn bạn đã đồng hành cùng Nối Số Biển Sâu! ❤️';
    }
  }

  String _getGratitudeTitleEn(int moc) {
    switch (moc) {
      case 3:
        return '3 days of exploration: Ocean call is ringing! 🐬';
      case 5:
        return 'Ocean melody: Connecting joyful moments! 🌊';
      case 7:
        return 'One week together: Explorer\'s glorious mark! 🎉';
      case 9:
        return 'Hidden treasures of the deep ocean 🐙';
      case 12:
        return 'Peaceful moments beneath the sea 💎';
      case 15:
        return 'Half a month: Glowing achievements! 📈';
      case 17:
        return 'Heart of the ocean: True champion spirit! ✨';
      case 19:
        return 'The endless magical sea voyage 🎯';
      case 21:
        return '3 weeks together: Heartfelt ocean thanks! 🏆';
      default:
        return 'Thank you for exploring Deep Sea Number Connect! ❤️';
    }
  }

  String _getGratitudeBodyVi(int moc) {
    switch (moc) {
      case 3:
        return 'Cảm ơn bạn đã hòa mình vào đại dương. Cùng khám phá những điều kỳ diệu hôm nay nhé! ❤️';
      case 5:
        return '5 ngày gắn bó, từng chuỗi số bạn nối là một giai điệu tuyệt đẹp dưới lòng biển sâu! ✨';
      case 7:
        return 'Một tuần đồng hành rực rỡ! Cùng viết tiếp hành trình chinh phục đỉnh cao mới nhé! ❤️';
      case 9:
        return 'Tư duy nhạy bén của bạn đã mở ra những sinh vật biển kỳ thú mới. Khám phá ngay thôi! 💡';
      case 12:
        return 'Mong những nhịp nối số êm dịu mang đến cho bạn cảm giác thư thái trọn vẹn mỗi ngày! 🌸';
      case 15:
        return '15 ngày đồng hành với bao kỷ lục ấn tượng. Cảm ơn bạn vì đã luôn ở đây cùng app! 💖';
      case 17:
        return 'Sự nhạy bén của bạn là chìa khóa chinh phục mọi thử thách. Bạn thật tuyệt vời! ❤️';
      case 19:
        return '19 ngày gắn kết. Những thử thách biển đêm ngọt ngào đang chờ bạn tối nay! 🌊';
      case 21:
        return 'Cảm ơn bạn đã biến Nối Số Biển Sâu thành một phần thói quen rèn luyện mỗi ngày! ❤️';
      default:
        return 'Cảm ơn bạn đã luôn tin tưởng và đồng hành cùng Nối Số Biển Sâu mỗi ngày. ❤️';
    }
  }

  String _getGratitudeBodyEn(int moc) {
    switch (moc) {
      case 3:
        return 'Thank you for diving in with us. Let\'s explore new underwater wonders today! ❤️';
      case 5:
        return '5 days together! Every number you connect creates a beautiful melody in the deep sea! ✨';
      case 7:
        return 'A brilliant week! Let\'s continue our journey to conquer new ocean heights! ❤️';
      case 9:
        return 'Your sharp mind has unlocked new fascinating sea creatures. Come explore now! 💡';
      case 12:
        return 'May these gentle number puzzles bring you pure relaxation every day! 🌸';
      case 15:
        return '15 days of amazing records. Thank you for being a part of our deep sea world! 💖';
      case 17:
        return 'Your sharp mind is the key to solving any puzzle. You are truly amazing! ❤️';
      case 19:
        return '19 days together. Sweet night ocean challenges are waiting for you tonight! 🌊';
      case 21:
        return 'Thank you for making Deep Sea Number Connect a part of your daily routine! ❤️';
      default:
        return 'Thank you for exploring Deep Sea Number Connect every day. ❤️';
    }
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted = await androidPlugin
        ?.requestNotificationsPermission();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final macGranted = await macosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted == true || iosGranted == true || macGranted == true;
  }

  Future<bool> hasNotificationPermission() async {
    await initialize();
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidEnabled = await androidPlugin?.areNotificationsEnabled();
    if (androidEnabled != null) {
      return androidEnabled;
    }
    return true;
  }

  Future<int> getPendingReminderCount() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }
}
