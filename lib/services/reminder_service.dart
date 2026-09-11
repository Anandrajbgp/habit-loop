import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/database_helper.dart';
import '../models/habit.dart';

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'habitloop_reminders';
  static const String _channelName = 'Habit reminders';
  static const String _channelDescription =
      'Scheduled reminders for habit completion';

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings);

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();

    final IOSFlutterLocalNotificationsPlugin? iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    final MacOSFlutterLocalNotificationsPlugin? macImpl =
        _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    await macImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> rescheduleAllHabits() async {
    try {
      await init();
      final List<Habit> habits = await DatabaseHelper.instance.getAllHabits();
      for (final Habit habit in habits) {
        await scheduleHabit(habit);
      }
    } catch (_) {
      // Keep app usable even if notification scheduling fails on a platform.
    }
  }

  Future<void> scheduleHabit(Habit habit) async {
    if (habit.id == null) {
      return;
    }

    try {
      await init();
      await cancelHabitReminders(habit.id!);

      if (!habit.reminderEnabled) {
        return;
      }

      final List<tz.TZDateTime> triggers = _buildUpcomingTriggers(habit);

      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      );

      for (int i = 0; i < triggers.length; i++) {
        await _plugin.zonedSchedule(
          _notificationId(habit.id!, i),
          habit.name,
          'Time to complete your habit',
          triggers[i],
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {
      // Ignore scheduling failures to avoid crashing user flow.
    }
  }

  Future<void> cancelHabitReminders(int habitId) async {
    try {
      await init();
      for (int i = 0; i < 400; i++) {
        await _plugin.cancel(_notificationId(habitId, i));
      }
    } catch (_) {
      // Ignore cancellation failures.
    }
  }

  List<tz.TZDateTime> _buildUpcomingTriggers(Habit habit) {
    final List<tz.TZDateTime> result = <tz.TZDateTime>[];
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    const int horizonDays = 60;

    if (habit.frequencyType == FrequencyType.specificDays) {
      final Set<int> weekdays = _parseWeekdays(habit.repeatDays);
      for (int i = 0; i < horizonDays; i++) {
        final tz.TZDateTime day = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: i));
        final tz.TZDateTime trigger = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          habit.reminderHour,
          habit.reminderMinute,
        );
        if (weekdays.contains(trigger.weekday) && trigger.isAfter(now)) {
          result.add(trigger);
        }
      }
      return result;
    }

    final int intervalDays = _resolveIntervalDays(habit);
    tz.TZDateTime trigger = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      habit.reminderHour,
      habit.reminderMinute,
    );

    while (!trigger.isAfter(now)) {
      trigger = trigger.add(Duration(days: intervalDays));
    }

    for (int i = 0; i < horizonDays; i += intervalDays) {
      result.add(trigger.add(Duration(days: i)));
    }

    return result;
  }

  int _resolveIntervalDays(Habit habit) {
    if (habit.frequencyType == FrequencyType.daily) {
      return 1;
    }
    if (habit.frequencyType == FrequencyType.interval) {
      return habit.frequencyValue < 1 ? 1 : habit.frequencyValue;
    }
    if (habit.frequencyType == FrequencyType.weeklyTimes) {
      final int times = habit.frequencyValue < 1 ? 1 : habit.frequencyValue;
      final int value = (7 / times).floor();
      return value < 1 ? 1 : value;
    }
    if (habit.frequencyType == FrequencyType.monthlyTimes) {
      final int times = habit.frequencyValue < 1 ? 1 : habit.frequencyValue;
      final int value = (30 / times).floor();
      return value < 1 ? 1 : value;
    }
    return 1;
  }

  Set<int> _parseWeekdays(String repeatDays) {
    final Set<int> days = <int>{};
    final List<String> parts = repeatDays.split(',');
    for (final String part in parts) {
      final int? day = int.tryParse(part.trim());
      if (day != null && day >= 1 && day <= 7) {
        days.add(day);
      }
    }
    if (days.isEmpty) {
      return <int>{1, 2, 3, 4, 5, 6, 7};
    }
    return days;
  }

  int _notificationId(int habitId, int slot) {
    return (habitId * 1000) + slot;
  }
}
