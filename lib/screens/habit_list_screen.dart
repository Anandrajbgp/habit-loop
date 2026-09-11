import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/habit.dart';
import '../data/database_helper.dart';
import '../widgets/habit_row.dart';
import 'add_habit_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import '../main.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

enum SortType { name, date, manual }

class _HabitListScreenState extends State<HabitListScreen> {
  late List<DateTime> _dates;
  List<Habit> _habits = [];
  Map<int, List<HabitRecord>> _recordsMap = {};
  bool _isLoading = true;
  SortType _currentSort = SortType.date;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadData();
  }

  void _generateDates() {
    final now = DateTime.now();
    _dates = List.generate(5, (index) => now.subtract(Duration(days: index)));
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper.instance;
      var habits = await db.getAllHabits();

      if (_currentSort == SortType.name) {
        habits.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      } else if (_currentSort == SortType.date) {
        habits.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      } else {
        habits.sort((a, b) => a.position.compareTo(b.position));
      }

      final Map<int, List<HabitRecord>> recordsMap = {};
      final start = DateTime.now().subtract(const Duration(days: 30));
      final end = DateTime.now().add(const Duration(days: 1));

      for (var habit in habits) {
        final records = await db.getRecordsForHabit(habit.id!, start, end);
        recordsMap[habit.id!] = records;
      }

      if (mounted) {
        setState(() {
          _habits = habits;
          _recordsMap = recordsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _launchFeedback() async {
    const String subject = 'habitloop app feedback';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'team.odlix@gmail.com',
      queryParameters: <String, String>{'subject': subject},
    );

    final bool launched = await launchUrl(
      emailLaunchUri,
      mode: LaunchMode.platformDefault,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            toolbarHeight: 80.0,
            floating: true,
            pinned: true,
            centerTitle: false,
            leading: IconButton(
              icon: Icon(Icons.menu_rounded, size: 30, color: headerTextColor),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Habits Tracker",
                  style: TextStyle(
                    color: headerTextColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                Text(
                  "by Odlix",
                  style: TextStyle(
                    fontSize: 12,
                    color: headerTextColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add_circle_rounded,
                  size: 30,
                  color: headerTextColor,
                ),
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const AddHabitScreen()),
                  );
                  if (res == true) _loadData();
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(child: _buildHeaderRow()),
            SliverReorderableList(
              itemCount: _habits.length,
              onReorderItem: _onReorderItem,
              itemBuilder: (context, index) {
                final h = _habits[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(h.id),
                  index: index,
                  child: HabitRow(
                    habit: h,
                    dates: _dates,
                    recentRecords: _recordsMap[h.id!] ?? [],
                    onRefresh: _loadData,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  void _onReorderItem(int oldIndex, int newIndex) async {
    setState(() {
      final item = _habits.removeAt(oldIndex);
      _habits.insert(newIndex, item);
      _currentSort = SortType.manual;
    });
    final db = DatabaseHelper.instance;
    for (int i = 0; i < _habits.length; i++) {
      final h = _habits[i];
      await db.updateHabit(
        Habit(
          id: h.id,
          name: h.name,
          question: h.question,
          type: h.type,
          frequencyType: h.frequencyType,
          frequencyValue: h.frequencyValue,
          targetValue: h.targetValue,
          unit: h.unit,
          color: h.color,
          repeatDays: h.repeatDays,
          position: i,
        ),
      );
    }
  }

  Widget _buildHeaderRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFF6200EE)
        : const Color(0xFFB8860B);
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            flex: 30,
            child: Text(
              "GOALS",
              style: TextStyle(
                color: textColor.withValues(alpha: 0.95),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ),
          ),
          Expanded(
            flex: 70,
            child: Row(
              children: _dates.map((d) {
                final isToday = DateTime.now().day == d.day;
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(d).toUpperCase().substring(0, 1),
                        style: TextStyle(
                          color: isToday
                              ? primaryColor
                              : textColor.withValues(alpha: 0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(d),
                        style: TextStyle(
                          color: isToday
                              ? primaryColor
                              : textColor.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF1C1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Habits Tracker",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "by Odlix",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFB8860B) : const Color(0xFF6200EE),
            ),
            title: Text(
              "Switch Theme",
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings_rounded,
              color: textColor.withValues(alpha: 0.7),
            ),
            title: Text(
              "Settings",
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.feedback_rounded,
              color: textColor.withValues(alpha: 0.7),
            ),
            title: Text(
              "Feedback",
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              _launchFeedback();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.info_rounded,
              color: textColor.withValues(alpha: 0.7),
            ),
            title: Text(
              "About",
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AboutScreen()),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "v 1.0.0",
              style: TextStyle(
                color: textColor.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
