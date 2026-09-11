import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        question TEXT,
        type INTEGER NOT NULL,
        frequencyType INTEGER NOT NULL DEFAULT 0,
        frequencyValue INTEGER NOT NULL DEFAULT 1,
        targetValue REAL NOT NULL DEFAULT 1.0,
        unit TEXT,
        color TEXT NOT NULL,
        repeatDays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        position INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        value REAL,
        isSkipped INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        FOREIGN KEY (habitId) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertHabit(Habit habit) async {
    final db = await instance.database;
    return await db.insert('habits', habit.toMap());
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await instance.database;
    return await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabit(int id) async {
    final db = await instance.database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habit>> getAllHabits() async {
    final db = await instance.database;
    final result = await db.query('habits');
    return result.map((json) => Habit.fromMap(json)).toList();
  }

  Future<int> insertRecord(HabitRecord record) async {
    final db = await instance.database;
    // Normalize date to YYYY-MM-DD for reliable matching
    final dateStr = record.date.toIso8601String().split('T')[0];
    
    final existing = await db.query(
      'habit_records',
      where: 'habitId = ? AND date LIKE ?',
      whereArgs: [record.habitId, '$dateStr%'],
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'];
      // Prepare map without ID for update
      final map = record.toMap();
      map.remove('id'); 
      return await db.update(
        'habit_records',
        map,
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await db.insert('habit_records', record.toMap());
    }
  }

  Future<List<HabitRecord>> getRecordsForHabit(int habitId, DateTime start, DateTime end) async {
    final db = await instance.database;
    // Use broad LIKE or BETWEEN carefully with strings
    final result = await db.query(
      'habit_records',
      where: 'habitId = ? AND date >= ? AND date <= ?',
      whereArgs: [habitId, start.toIso8601String(), end.toIso8601String()],
    );
    return result.map((json) => HabitRecord.fromMap(json)).toList();
  }
}
