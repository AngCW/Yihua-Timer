import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import '../app_config.dart';
import '../database/app_database.dart';
import '../database/event_transfer.dart';

class PreviousVersionInfo {
  final String version;
  final String path;
  final File dbFile;
  final List<String> eventNames;

  PreviousVersionInfo({
    required this.version,
    required this.path,
    required this.dbFile,
    required this.eventNames,
  });
}

class MigrationService {
  static Future<List<PreviousVersionInfo>> detectPreviousVersions() async {
    final supportDir = await getApplicationSupportDirectory();
    // Parent of the current versioned folder should be the YiHuaTimer base folder.
    // For release: YiHuaTimer/v1.6.0 -> Parent is YiHuaTimer
    // For debug: YiHuaTimer/debug -> Parent is YiHuaTimer
    final currentPath = AppConfig.dataPath(supportDir.path);
    final yihuaBase = Directory(p.dirname(currentPath));
    
    if (!await yihuaBase.exists()) return [];

    final List<PreviousVersionInfo> versions = [];

    // 1. Check for versioned folders (e.g., v1.7.0)
    await for (final entity in yihuaBase.list()) {
      if (entity is Directory) {
        if (p.canonicalize(entity.path) == p.canonicalize(currentPath)) continue;
        
        final dbFile = File(p.join(entity.path, 'yihua_timer.db'));
        if (await dbFile.exists()) {
          final folderName = p.basename(entity.path);
          String versionStr = folderName;
          if (folderName.startsWith('v')) {
            versionStr = folderName.substring(1);
          } else if (folderName == 'debug') {
            versionStr = '调试版 (Debug)';
          }
          
          versions.add(PreviousVersionInfo(
            version: versionStr,
            path: entity.path,
            dbFile: dbFile,
            eventNames: _getEventNames(dbFile),
          ));
        }
      }
    }

    // 2. Check root for legacy version (<= 1.6.0)
    // If there is a yihua_timer.db directly in the supportDir or yihuaBase
    final legacyDb = File(p.join(yihuaBase.path, 'yihua_timer.db'));
    if (await legacyDb.exists()) {
       versions.add(PreviousVersionInfo(
         version: '1.6.0 及以下',
         path: yihuaBase.path,
         dbFile: legacyDb,
         eventNames: _getEventNames(legacyDb),
       ));
    }

    return versions;
  }

  static List<String> _getEventNames(File dbFile) {
    sqlite.Database? db;
    try {
      db = sqlite.sqlite3.open(dbFile.path);
      // Check if event table exists
      final tableCheck = db.select("SELECT name FROM sqlite_master WHERE type='table' AND name='event'");
      if (tableCheck.isEmpty) return [];

      final results = db.select('SELECT event_name FROM event LIMIT 5');
      final names = results.map((row) => row['event_name'] as String).toList();
      
      final countResult = db.select('SELECT COUNT(*) as cnt FROM event');
      final total = countResult.first['cnt'] as int;
      if (total > 5) {
        names.add('... 等共 $total 个赛事');
      }
      return names;
    } catch (e) {
      print('Error reading previous database: $e');
      return ['无法读取赛事数据'];
    } finally {
      db?.dispose();
    }
  }

  static Future<void> migrateFrom(PreviousVersionInfo info) async {
    final oldDb = AppDatabase.forFile(info.dbFile);
    try {
      final events = await oldDb.select(oldDb.event).get();
      for (var event in events) {
        final data = await EventTransfer.exportEventToMap(event, sourceDb: oldDb);
        // assetSourceDir should be the folder containing 'images', 'schools', etc.
        // info.path is exactly that folder.
        await EventTransfer.importEventData(data, Directory(info.path));
      }
    } finally {
      await oldDb.close();
    }
  }
}
