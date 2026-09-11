import 'package:flutter/material.dart';

import 'dart:math' as math; // Fixed missing import

import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/habit.dart';
import '../data/database_helper.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  List<HabitRecord> _allRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final start = DateTime.now().subtract(const Duration(days: 365));
    final end = DateTime.now().add(const Duration(days: 1));
    final records = await DatabaseHelper.instance.getRecordsForHabit(
      widget.habit.id!,
      start,
      end,
    );
    setState(() {
      _allRecords = records;
      _isLoading = false;
    });
  }

  int _calculateStreak() {
    if (_allRecords.isEmpty) return 0;
    _allRecords.sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime check = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (int i = 0; i < 365; i++) {
      final date = check.subtract(Duration(days: i));
      final rec = _allRecords.firstWhere(
        (r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day,
        orElse: () => HabitRecord(habitId: 0, date: date, value: 0),
      );
      if (rec.value == 1.0) {
        streak++;
      } else if (i == 0)
        continue;
      else
        break;
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(
      int.parse(widget.habit.color.replaceAll('#', '0xFF')),
    );
    final textColor = isDark ? Colors.white : const Color(0xFF432C0B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.habit.name,
          style: TextStyle(color: habitColor, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        "Current Streak",
                        "${_calculateStreak()} days",
                        habitColor,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        "Records",
                        "${_allRecords.where((r) => r.value == 1.0).length} total",
                        habitColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildHeader("STRENGTH"),
                  const SizedBox(height: 12),
                  _buildChart(habitColor),
                  const SizedBox(height: 32),
                  _buildHeader("HISTORY"),
                  const SizedBox(height: 12),
                  _buildCalendar(habitColor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String t, String v, Color c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.1),
            width: 2,
          ),
        ), // Fixed black10 error
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              v,
              style: TextStyle(
                color: c,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildChart(Color c) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                30,
                (i) => FlSpot(i.toDouble(), math.Random().nextDouble() * 10),
              ),
              isCurved: true,
              color: c,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: c.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(Color c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.now(),
        headerStyle: HeaderStyle(
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          formatButtonVisible: false,
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final rec = _allRecords.firstWhere(
              (r) =>
                  r.date.year == day.year &&
                  r.date.month == day.month &&
                  r.date.day == day.day,
              orElse: () => HabitRecord(habitId: 0, date: day, value: 0),
            );
            if (rec.value == 1.0)
              return Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    "${day.day}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            if (rec.value == 0.0)
              return Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${day.day}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              );
            return null;
          },
        ),
      ),
    );
  }
}
