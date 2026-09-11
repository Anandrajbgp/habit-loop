enum HabitType { binary, quantitative }
enum FrequencyType { daily, weeklyTimes, monthlyTimes, specificDays, interval }

class Habit {
  final int? id;
  final String name;
  final String question;
  final HabitType type;
  final FrequencyType frequencyType;
  final int frequencyValue;
  final double targetValue;
  final String? unit; // e.g., "miles", "pages"
  final String color; // Hex string
  final String repeatDays; // e.g., "1,2,3,4,5,6,7" for daily
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int position; // For manual reordering

  Habit({
    this.id,
    required this.name,
    this.question = "",
    required this.type,
    this.frequencyType = FrequencyType.daily,
    this.frequencyValue = 1,
    this.targetValue = 1.0,
    this.unit,
    required this.color,
    this.repeatDays = "1,2,3,4,5,6,7",
    this.reminderEnabled = true,
    this.reminderHour = 8,
    this.reminderMinute = 0,
    this.position = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'question': question,
      'type': type.index,
      'frequencyType': frequencyType.index,
      'frequencyValue': frequencyValue,
      'targetValue': targetValue,
      'unit': unit,
      'color': color,
      'repeatDays': repeatDays,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'position': position,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      name: map['name'],
      question: map['question'] ?? "",
      type: HabitType.values[map['type']],
      frequencyType: FrequencyType.values[map['frequencyType'] ?? 0],
      frequencyValue: map['frequencyValue'] ?? 1,
      targetValue: (map['targetValue'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'],
      color: map['color'],
      repeatDays: map['repeatDays'] ?? "1,2,3,4,5,6,7",
      reminderEnabled: (map['reminderEnabled'] ?? 1) == 1,
      reminderHour: map['reminderHour'] ?? 8,
      reminderMinute: map['reminderMinute'] ?? 0,
      position: map['position'] ?? 0,
    );
  }
}

class HabitRecord {
  final int? id;
  final int habitId;
  final DateTime date;
  final double? value; // null for binary (or 1.0 for done), numeric for quantitative
  final bool isSkipped;
  final String note;

  HabitRecord({
    this.id,
    required this.habitId,
    required this.date,
    this.value,
    this.isSkipped = false,
    this.note = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'value': value,
      'isSkipped': isSkipped ? 1 : 0,
      'note': note,
    };
  }

  factory HabitRecord.fromMap(Map<String, dynamic> map) {
    return HabitRecord(
      id: map['id'],
      habitId: map['habitId'],
      date: DateTime.parse(map['date']),
      value: (map['value'] as num?)?.toDouble(),
      isSkipped: map['isSkipped'] == 1,
      note: map['note'] ?? "",
    );
  }
}
