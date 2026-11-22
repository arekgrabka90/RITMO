import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;
  static Future<Database> get instance async => _db ??= await _open();

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'napiwnik.db'),
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
        await db.execute(
            'CREATE TABLE workplaces(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
        await db.execute('''
          CREATE TABLE tips(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workplace_id INTEGER REFERENCES workplaces(id) ON DELETE SET NULL,
            date TEXT NOT NULL,
            cash INTEGER NOT NULL DEFAULT 0,
            card INTEGER NOT NULL DEFAULT 0,
            tip_out INTEGER NOT NULL DEFAULT 0,
            hours REAL,
            note TEXT NOT NULL DEFAULT ''
          )''');
        await db.execute('CREATE INDEX idx_tips_date ON tips(date)');
        await _createShifts(db);
      },
      // Każda zmiana schematu = nowa wersja + migracja tutaj (bez kasowania danych).
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) await _createShifts(db);
      },
    );
  }

  /// Wersja 2: grafik. date = dzień rozpoczęcia zmiany, start_min i end_min = minuty od północy.
  /// Gdy end_min <= start_min, zmiana kończy się następnego dnia. tip_id = wpis napiwków do tej zmiany.
  static Future<void> _createShifts(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workplace_id INTEGER REFERENCES workplaces(id) ON DELETE SET NULL,
        date TEXT NOT NULL,
        start_min INTEGER NOT NULL,
        end_min INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        tip_id INTEGER REFERENCES tips(id) ON DELETE SET NULL
      )''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_date ON shifts(date)');
  }
}
