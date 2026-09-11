import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../screens/add_habit_screen.dart';
import 'status_cell.dart';

class HabitRow extends StatelessWidget {
  final Habit habit;
  final List<HabitRecord> recentRecords;
  final List<DateTime> dates;
  final VoidCallback? onRefresh;

  const HabitRow({
    super.key,
    required this.habit,
    required this.recentRecords,
    required this.dates,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(int.parse(habit.color.replaceAll('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, color: habitColor),
            // 30% Area for Habit Name
            Expanded(
              flex: 30,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddHabitScreen(habit: habit),
                    ),
                  );
                  if (result == true && onRefresh != null) onRefresh!();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    habit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: habitColor,
                      fontSize: 16, // Increased from 14
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            // 70% Area for 5-Day Grid
            Expanded(
              flex: 70,
              child: Row(
                children: dates.map((date) {
                  final record = recentRecords.firstWhere(
                    (r) =>
                        r.date.year == date.year &&
                        r.date.month == date.month &&
                        r.date.day == date.day,
                    orElse: () => HabitRecord(
                      habitId: habit.id!,
                      date: date,
                      value: null,
                    ),
                  );
                  return Expanded(
                    child: StatusCell(
                      habit: habit,
                      record: record,
                      color: habitColor,
                      onRefresh: onRefresh,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
