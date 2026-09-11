import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../data/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _stickyNotifications = false;
  String _firstDayOfWeek = "Sunday";
  bool _notificationsEnabled = true;
  bool _notificationSound = true;
  bool _notificationVibration = true;
  bool _notificationLights = true;
  bool _notificationHeadsUp = true;
  bool _notificationCriticalAlert = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);

  late SharedPreferences _prefs;
  bool _isPrefsReady = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _stickyNotifications = _prefs.getBool('sticky_notifications') ?? false;
      _firstDayOfWeek = _prefs.getString('first_day_of_week') ?? "Sunday";
      _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
      _notificationSound = _prefs.getBool('notification_sound') ?? true;
      _notificationVibration = _prefs.getBool('notification_vibration') ?? true;
      _notificationLights = _prefs.getBool('notification_lights') ?? true;
      _notificationHeadsUp = _prefs.getBool('notification_heads_up') ?? true;
      _notificationCriticalAlert =
          _prefs.getBool('notification_critical_alert') ?? false;
      final int hour = _prefs.getInt('notification_hour') ?? 8;
      final int minute = _prefs.getInt('notification_minute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
      _isPrefsReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPrefsReady)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSettingTile(
            title: "First day of the week",
            subtitle: _firstDayOfWeek,
            onTap: _showDayPicker,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "Reminder",
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF6200EE)
                    : const Color(0xFFB8860B),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          _buildSwitchTile(
            title: "Make notifications sticky",
            subtitle: "Prevents notifications from being swiped away.",
            value: _stickyNotifications,
            onChanged: (val) {
              setState(() => _stickyNotifications = val);
              _prefs.setBool('sticky_notifications', val);
            },
          ),
          _buildSettingTile(
            title: "Customize notifications",
            subtitle: "Manage reminder options and delivery behavior",
            onTap: _showNotificationSettingsSheet,
          ),
          const Divider(height: 32),
          _buildSettingTile(
            title: "Export as CSV",
            subtitle: "Generates files that can be opened by spreadsheet software. This file cannot be imported back.",
            onTap: _exportCSV,
          ),
        ],
      ),
    );
  }

  void _showDayPicker() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("First day of the week"),
        children:
            [
                  "Sunday",
                  "Monday",
                  "Tuesday",
                  "Wednesday",
                  "Thursday",
                  "Friday",
                  "Saturday",
                ]
                .map(
                  (day) => SimpleDialogOption(
                    onPressed: () {
                      setState(() => _firstDayOfWeek = day);
                      _prefs.setString('first_day_of_week', day);
                      Navigator.pop(context);
                    },
                    child: Text(day),
                  ),
                )
                .toList(),
      ),
    );
  }

  Future<void> _pickNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );

    if (picked != null) {
      setState(() => _notificationTime = picked);
      await _prefs.setInt('notification_hour', picked.hour);
      await _prefs.setInt('notification_minute', picked.minute);
    }
  }

  Future<void> _showNotificationSettingsSheet() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Customize notifications",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildModalSwitchTile(
                        title: "Enable reminders",
                        subtitle: "Turn all habit reminders on or off",
                        value: _notificationsEnabled,
                        onChanged: (bool val) async {
                          setState(() => _notificationsEnabled = val);
                          setModalState(() => _notificationsEnabled = val);
                          await _prefs.setBool('notifications_enabled', val);
                        },
                      ),
                      _buildModalSwitchTile(
                        title: "Sound",
                        subtitle: "Play sound when reminder appears",
                        value: _notificationSound,
                        onChanged: (bool val) async {
                          setState(() => _notificationSound = val);
                          setModalState(() => _notificationSound = val);
                          await _prefs.setBool('notification_sound', val);
                        },
                      ),
                      _buildModalSwitchTile(
                        title: "Vibration",
                        subtitle: "Vibrate device for reminders",
                        value: _notificationVibration,
                        onChanged: (bool val) async {
                          setState(() => _notificationVibration = val);
                          setModalState(() => _notificationVibration = val);
                          await _prefs.setBool('notification_vibration', val);
                        },
                      ),
                      _buildModalSwitchTile(
                        title: "Notification light",
                        subtitle:
                            "Blink device notification LED when available",
                        value: _notificationLights,
                        onChanged: (bool val) async {
                          setState(() => _notificationLights = val);
                          setModalState(() => _notificationLights = val);
                          await _prefs.setBool('notification_lights', val);
                        },
                      ),
                      _buildModalSwitchTile(
                        title: "Heads-up notifications",
                        subtitle: "Show pop-up alerts on screen",
                        value: _notificationHeadsUp,
                        onChanged: (bool val) async {
                          setState(() => _notificationHeadsUp = val);
                          setModalState(() => _notificationHeadsUp = val);
                          await _prefs.setBool('notification_heads_up', val);
                        },
                      ),
                      _buildModalSwitchTile(
                        title: "Critical alerts",
                        subtitle: "High priority reminders (if supported)",
                        value: _notificationCriticalAlert,
                        onChanged: (bool val) async {
                          setState(() => _notificationCriticalAlert = val);
                          setModalState(() => _notificationCriticalAlert = val);
                          await _prefs.setBool(
                            'notification_critical_alert',
                            val,
                          );
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Default reminder time",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _notificationTime.format(context),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () async {
                          await _pickNotificationTime();
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportCSV() async {
    final db = DatabaseHelper.instance;
    final habits = await db.getAllHabits();

    List<List<dynamic>> rows = [];
    rows.add(["Habit Name", "Date", "Status", "Note"]);

    for (var habit in habits) {
      final records = await db.getRecordsForHabit(
        habit.id!,
        DateTime.now().subtract(const Duration(days: 365)),
        DateTime.now(),
      );
      for (var record in records) {
        rows.add([
          habit.name,
          record.date.toIso8601String().split('T')[0],
          record.value == 1.0 ? "Completed" : "Missed/Crossed",
          record.note,
        ]);
      }
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/habits_export.csv");
    await file.writeAsString(csvData);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'My Habit Tracker Export');
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      activeThumbColor: isDark
          ? const Color(0xFF6200EE)
          : const Color(0xFFB8860B),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildModalSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: isDark
          ? const Color(0xFF6200EE)
          : const Color(0xFFB8860B),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13),
      ),
    );
  }
}
