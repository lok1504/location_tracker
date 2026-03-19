import 'dart:developer';

import 'package:location_tracker/models/models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Future<void> insertGroup(Group group) async {
    final db = await database;
    final result = await db.insert('group', group.toMap());

    if (result == 0) {
      throw Exception('Failed to insert group');
    }

    log('Inserted group');
  }

  Future<void> insertLocationLog(LocationLog locationLog) async {
    final db = await database;
    final result = await db.insert('locationLog', locationLog.toMap());

    if (result == 0) {
      throw Exception('Failed to insert location log');
    }

    log('Inserted location log');
  }

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app.db');

    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE "group" (
            id TEXT NOT NULL,
            type TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            CONSTRAINT "PK_group_id" PRIMARY KEY (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE locationLog (
            id TEXT NOT NULL,
            groupId TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL NOT NULL,
            altitude REAL NOT NULL,
            altitudeAccuracy REAL NOT NULL,
            heading REAL NOT NULL,
            headingAccuracy REAL NOT NULL,
            speed REAL NOT NULL,
            speedAccuracy REAL NOT NULL,
            createdAt TEXT NOT NULL,
            CONSTRAINT "PK_locationLog_id" PRIMARY KEY (id),
            CONSTRAINT "FK_locationLog_groupId" FOREIGN KEY (groupId) REFERENCES "group" (id)
          )
        ''');
      },
      version: 1,
    );
  }
}
