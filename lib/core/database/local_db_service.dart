import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// Local Offline Database Service for GROWTH OS
/// Provides zero-latency offline persistence and automatic sync queueing
class LocalDbService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'growth_os_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Local Profiles
        await db.execute('''
          CREATE TABLE local_profiles (
            id TEXT PRIMARY KEY,
            full_name TEXT,
            business_name TEXT,
            avatar_url TEXT,
            youtube_channel TEXT,
            instagram_username TEXT,
            telegram_channel TEXT,
            monthly_earning_target REAL,
            annual_earning_target REAL,
            primary_category TEXT,
            preferred_currency TEXT,
            streak_count INTEGER,
            is_admin INTEGER DEFAULT 0
          )
        ''');

        // 2. Local Projects
        await db.execute('''
          CREATE TABLE local_projects (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            name TEXT,
            category TEXT,
            description TEXT,
            start_date TEXT,
            deadline TEXT,
            priority TEXT,
            status TEXT,
            expected_result TEXT,
            progress_percentage INTEGER,
            reminder_enabled INTEGER,
            is_synced INTEGER DEFAULT 0
          )
        ''');

        // 3. Local Stages
        await db.execute('''
          CREATE TABLE local_stages (
            id TEXT PRIMARY KEY,
            project_id TEXT,
            stage_order INTEGER,
            title TEXT,
            description TEXT,
            is_completed INTEGER,
            weight INTEGER,
            is_synced INTEGER DEFAULT 0
          )
        ''');

        // 4. Local Updates & Journey
        await db.execute('''
          CREATE TABLE local_updates (
            id TEXT PRIMARY KEY,
            project_id TEXT,
            stage_id TEXT,
            update_text TEXT,
            result_achieved TEXT,
            problem_loss TEXT,
            learning_notes TEXT,
            earnings_recorded REAL,
            losses_recorded REAL,
            created_at TEXT,
            is_synced INTEGER DEFAULT 0
          )
        ''');

        // 5. Local Financial Records
        await db.execute('''
          CREATE TABLE local_income (
            id TEXT PRIMARY KEY,
            project_id TEXT,
            amount REAL,
            platform_source TEXT,
            category TEXT,
            description TEXT,
            payment_status TEXT,
            entry_date TEXT,
            is_synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE local_expenses (
            id TEXT PRIMARY KEY,
            project_id TEXT,
            amount REAL,
            category TEXT,
            description TEXT,
            is_loss INTEGER,
            entry_date TEXT,
            is_synced INTEGER DEFAULT 0
          )
        ''');

        // 6. Local Clients (CRM)
        await db.execute('''
          CREATE TABLE local_clients (
            id TEXT PRIMARY KEY,
            name TEXT,
            contact_person TEXT,
            phone TEXT,
            whatsapp_number TEXT,
            email TEXT,
            company_name TEXT,
            deal_amount REAL,
            lead_status TEXT,
            work_deadline TEXT,
            follow_up_date TEXT,
            notes TEXT,
            is_synced INTEGER DEFAULT 0
          )
        ''');

        // 7. Sync Queue
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT,
            record_id TEXT,
            action TEXT, -- INSERT, UPDATE, DELETE
            payload TEXT,
            created_at TEXT
          )
        ''');

        debugPrint('[LocalDbService] Offline database schema initialized.');
      },
    );
  }

  // Insert or update helper
  static Future<void> upsert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Query helper
  static Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  // Delete helper
  static Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}

