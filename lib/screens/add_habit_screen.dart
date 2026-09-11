import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../data/database_helper.dart';
import '../services/reminder_service.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedColor = "#2196F3";
  String _selectedFrequency = "Every day";
  TimeOfDay? _selectedTime;

  int _everyXDaysValue = 3;
  int _timesPerWeekValue = 3;
  int _timesPerMonthValue = 10;
  int _xTimesValue = 3;
  int _inYDaysValue = 14;

  final List<String> _colors = [
    "#2196F3",
    "#E91E63",
    "#FF9800",
    "#4CAF50",
    "#9C27B0",
    "#F44336",
    "#00BCD4",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.question;
      _selectedColor = widget.habit!.color;
      _selectedTime = TimeOfDay(
        hour: widget.habit!.reminderHour,
        minute: widget.habit!.reminderMinute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFFFFDF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.habit == null ? "Create habit" : "Edit habit",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (widget.habit != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              onPressed: _deleteHabit,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: OutlinedButton(
              onPressed: _saveHabit,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                "SAVE",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildOutlineContainer(
                    label: "Name",
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ), // Increased to 24
                      decoration: const InputDecoration(
                        hintText: "e.g. Exercise",
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildOutlineContainer(
                    label: "Color",
                    child: GestureDetector(
                      onTap: _showColorPicker,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(_selectedColor.replaceAll('#', '0xFF')),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildOutlineContainer(
              label: "Description",
              child: TextField(
                controller: _descriptionController,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                ), // Increased to 20
                decoration: const InputDecoration(
                  hintText: "e.g. Morning workout for 30 mins",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildOutlineContainer(
              label: "Frequency",
              child: InkWell(
                onTap: _showFrequencyDialog,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFrequency,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ), // Increased to 20
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildOutlineContainer(
              label: "Reminder",
              child: InkWell(
                onTap: _pickTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTime == null
                            ? "Off"
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ), // Increased to 20
                      ),
                      Icon(
                        Icons.access_time_rounded,
                        color: primaryColor.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineContainer({
    required String label,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.2);

    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: isDark ? const Color(0xFF121212) : const Color(0xFFFFFDF5),
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16, // Increased from 12
                fontWeight: FontWeight.w900, // Extra bold
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFrequencyDialog() {
    String localSelected = _selectedFrequency;
    if (![
      "Every day",
      "Every X days",
      "X times per week",
      "X times per month",
      "X times in Y days",
    ].contains(localSelected)) {
      localSelected = "Every day";
    }

    final xDaysController = TextEditingController(
      text: _everyXDaysValue.toString(),
    );
    final weekController = TextEditingController(
      text: _timesPerWeekValue.toString(),
    );
    final monthController = TextEditingController(
      text: _timesPerMonthValue.toString(),
    );
    final timesController = TextEditingController(
      text: _xTimesValue.toString(),
    );
    final inDaysController = TextEditingController(
      text: _inYDaysValue.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          backgroundColor: const Color(0xFF333333),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFreqOption(
                setLocalState,
                "Every day",
                localSelected,
                (val) => localSelected = val,
                const Text(
                  "Every day",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              _buildFreqOption(
                setLocalState,
                "Every X days",
                localSelected,
                (val) => localSelected = val,
                Row(
                  children: [
                    const Text(
                      "Every ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    _buildFreqInput(xDaysController),
                    const Text(
                      " days",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFreqOption(
                setLocalState,
                "X times per week",
                localSelected,
                (val) => localSelected = val,
                Row(
                  children: [
                    _buildFreqInput(weekController),
                    const Text(
                      " times per week",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFreqOption(
                setLocalState,
                "X times per month",
                localSelected,
                (val) => localSelected = val,
                Row(
                  children: [
                    _buildFreqInput(monthController),
                    const Text(
                      " times per month",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFreqOption(
                setLocalState,
                "X times in Y days",
                localSelected,
                (val) => localSelected = val,
                Row(
                  children: [
                    _buildFreqInput(timesController),
                    const Text(
                      " times in ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    _buildFreqInput(inDaysController),
                    const Text(
                      " days",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _everyXDaysValue =
                          int.tryParse(xDaysController.text) ?? 1;
                      _timesPerWeekValue =
                          int.tryParse(weekController.text) ?? 1;
                      _timesPerMonthValue =
                          int.tryParse(monthController.text) ?? 1;
                      _xTimesValue = int.tryParse(timesController.text) ?? 1;
                      _inYDaysValue = int.tryParse(inDaysController.text) ?? 1;
                      if (localSelected == "Every day") {
                        _selectedFrequency = "Every day";
                      } else if (localSelected == "Every X days") {
                        _selectedFrequency = "Every $_everyXDaysValue days";
                      } else if (localSelected == "X times per week") {
                        _selectedFrequency =
                            "$_timesPerWeekValue times per week";
                      } else if (localSelected == "X times per month") {
                        _selectedFrequency =
                            "$_timesPerMonthValue times per month";
                      } else if (localSelected == "X times in Y days") {
                        _selectedFrequency =
                            "$_xTimesValue times in $_inYDaysValue days";
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "SAVE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreqOption(
    StateSetter setLocalState,
    String value,
    String current,
    Function(String) onSelect,
    Widget content,
  ) {
    return InkWell(
      onTap: () => setLocalState(() => onSelect(value)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setLocalState(() => onSelect(value)),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: current == value
                        ? const Color(0xFF2196F3)
                        : Colors.white54,
                    width: 2,
                  ),
                ),
                child: current == value
                    ? const Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 10, height: 10),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqInput(TextEditingController controller) {
    return Container(
      width: 45,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.only(top: 6),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Color"),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors
              .map(
                (c) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = c);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: _selectedColor == c
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _saveHabit() async {
    if (_nameController.text.isEmpty) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    final int defaultHour = prefs.getInt('notification_hour') ?? 8;
    final int defaultMinute = prefs.getInt('notification_minute') ?? 0;

    final TimeOfDay reminderTime =
        _selectedTime ?? TimeOfDay(hour: defaultHour, minute: defaultMinute);

    final Habit habit = Habit(
      id: widget.habit?.id,
      name: _nameController.text.trim(),
      question: _descriptionController.text.trim(),
      type: HabitType.binary,
      color: _selectedColor,
      repeatDays: "1,2,3,4,5,6,7",
      reminderEnabled: notificationsEnabled,
      reminderHour: reminderTime.hour,
      reminderMinute: reminderTime.minute,
    );

    int? habitId = widget.habit?.id;
    if (widget.habit == null) {
      habitId = await DatabaseHelper.instance.insertHabit(habit);
    } else {
      await DatabaseHelper.instance.updateHabit(habit);
    }

    final Habit scheduledHabit = Habit(
      id: habitId,
      name: habit.name,
      question: habit.question,
      type: habit.type,
      frequencyType: habit.frequencyType,
      frequencyValue: habit.frequencyValue,
      targetValue: habit.targetValue,
      unit: habit.unit,
      color: habit.color,
      repeatDays: habit.repeatDays,
      reminderEnabled: habit.reminderEnabled,
      reminderHour: habit.reminderHour,
      reminderMinute: habit.reminderMinute,
      position: habit.position,
    );

    await ReminderService.instance.scheduleHabit(scheduledHabit);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _deleteHabit() async {
    if (widget.habit?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Habit?"),
        content: const Text(
          "Are you sure you want to delete this habit and all its records?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final int habitId = widget.habit!.id!;
      await DatabaseHelper.instance.deleteHabit(habitId);
      await ReminderService.instance.cancelHabitReminders(habitId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
