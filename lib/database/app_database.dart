import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

@DriftDatabase(include: {'tables.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ─────────────────────────────────────────────────────────────────────────
  // HOW TO ADD A SCHEMA CHANGE:
  //
  // 1. Edit lib/database/tables.drift with your new column/table.
  // 2. Bump schemaVersion below by 1.
  // 3. Add an `if (from < <new version>)` block in onUpgrade that calls the
  //    appropriate Migrator method (addColumn, createTable, etc.).
  // 4. Run: flutter pub run build_runner build --delete-conflicting-outputs
  //
  // In DEBUG builds the app also calls _validateOrRepairSchema() on every
  // open, which automatically creates missing tables and adds missing columns.
  // This lets you iterate quickly without losing existing data.
  // In RELEASE builds only the explicit onUpgrade steps run.
  // ─────────────────────────────────────────────────────────────────────────

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // ── version-gated migration steps ────────────────────────────────
        if (from < 4) {
          await m.createTable(flowFolder);
          await m.addColumn(flow, flow.folderId);
        }
        if (from < 5) {
          await m.addColumn(flow, flow.sectionFontName);
          await m.addColumn(flow, flow.timerFontName);
          await m.addColumn(page, page.sectionFontName);
          await m.addColumn(page, page.timerFontName);
        }
        if (from < 6) {
          await m.createTable(position);
          await m.addColumn(images, images.positionId);
        }
        if (from < 7) {
          await m.addColumn(timer, timer.positionId);
          await m.addColumn(page, page.sectionPositionId);
        }
        // ── add new `if (from < N)` blocks above this line ───────────────
      },
      beforeOpen: (details) async {
        // In debug mode, automatically repair any schema drift between
        // tables.drift and the live SQLite file.  Safe to run on every open
        // because createTable uses IF NOT EXISTS and addColumn is no-op safe.
        if (kDebugMode) {
          await _validateOrRepairSchema();
        }
      },
    );
  }

  /// Checks that every table and column from the Drift definition actually
  /// exists in the live SQLite file.  Any missing table is created and any
  /// missing column is added via ALTER TABLE … ADD COLUMN.
  /// This is ONLY called in debug mode; release builds rely purely on
  /// versioned onUpgrade steps.
  Future<void> _validateOrRepairSchema() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      final m = Migrator(this);

      for (final tbl in allTables) {
        // createTable uses IF NOT EXISTS — safe to call even if table exists.
        await m.createTable(tbl);
      }

      for (final tbl in allTables) {
        final rows = await customSelect(
          'PRAGMA table_info("${tbl.actualTableName}")',
        ).get();
        final existingColumns = rows.map((r) => r.read<String>('name')).toSet();

        for (final col in tbl.$columns) {
          if (!existingColumns.contains(col.name)) {
            await m.addColumn(tbl, col);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DB] _validateOrRepairSchema error: $e');
      }
    } finally {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // getApplicationSupportDirectory maps to AppData/Roaming on Windows.
    final supportDir = await getApplicationSupportDirectory();
    final appFolder = Directory(p.join(supportDir.path, 'YiHuaTimer'));

    if (!await appFolder.exists()) {
      await appFolder.create(recursive: true);
    }

    // Proactive access check (optional but good for debugging)
    try {
      final testFile = File(p.join(appFolder.path, '.access_test'));
      await testFile.writeAsString('access test');
      await testFile.delete();
      if (kDebugMode) {
        print('Database directory verified at: ${appFolder.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CRITICAL: Persistent access failure in AppData. Error: $e');
      }
    }

    final file = File(p.join(appFolder.path, 'yihua_timer.db'));

    if (Platform.isWindows) {
      try {
        final cachebase = (await getTemporaryDirectory()).path;
        final tempDir = Directory(p.join(cachebase, 'yihua_sqlite_temp'));
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        sqlite3.tempDirectory = tempDir.path;
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Could not set sqlite3 temp directory: $e');
        }
      }
    }

    return NativeDatabase.createInBackground(file);
  });
}
