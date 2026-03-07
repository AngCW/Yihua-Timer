import 'dart:io';

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

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
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
      },
    );
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
      print('Database directory verified at: ${appFolder.path}');
    } catch (e) {
      print('CRITICAL: Persistent access failure in AppData. Error: $e');
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
        print('Warning: Could not set sqlite3 temp directory: $e');
      }
    }

    return NativeDatabase.createInBackground(file);
  });
}
