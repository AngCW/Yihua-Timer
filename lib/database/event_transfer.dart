import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../main.dart';
import '../app_config.dart';

class EventTransfer {
  static Future<Map<String, dynamic>> exportEventToMap(EventData event, {AppDatabase? sourceDb}) async {
    final db = sourceDb ?? database;
    final Map<String, dynamic> exportData = {};

    // 1. Fetch all database records related to the event
    exportData['event'] = event.toJson();

    final schools = await (db.select(db.school)
          ..where((t) => t.eventId.equals(event.id)))
        .get();
    exportData['school'] = schools.map((s) => s.toJson()).toList();

    final flowFolders = await (db.select(db.flowFolder)
          ..where((t) => t.eventId.equals(event.id)))
        .get();
    exportData['flow_folder'] = flowFolders.map((ff) => ff.toJson()).toList();

    final flows = await (db.select(db.flow)
          ..where((t) => t.eventId.equals(event.id)))
        .get();
    exportData['flow'] = flows.map((f) => f.toJson()).toList();

    final List<Map<String, dynamic>> pagesJson = [];
    final List<Map<String, dynamic>> timersJson = [];
    final List<Map<String, dynamic>> imagesJson = [];
    final Set<int> exportedImageIds = {};
    final Set<int> positionIds = {};
    final Set<int> templateIds = {};
    final Set<int> bgmIds = {};
    final Set<int> dingAudioIds = {};

    for (var flow in flows) {
      final pages = await (db.select(db.page)
            ..where((t) => t.flowId.equals(flow.id)))
          .get();
      for (var page in pages) {
        pagesJson.add(page.toJson());
        if (page.sectionPositionId != null) positionIds.add(page.sectionPositionId!);
        if (page.schoolAPositionId != null) positionIds.add(page.schoolAPositionId!);
        if (page.schoolBPositionId != null) positionIds.add(page.schoolBPositionId!);
        if (page.bgmId != null) bgmIds.add(page.bgmId!);

        final timers = await (db.select(db.timer)
              ..where((t) => t.pageId.equals(page.id)))
            .get();
        for (var timer in timers) {
          timersJson.add(timer.toJson());
          if (timer.positionId != null) positionIds.add(timer.positionId!);
          if (timer.timerTemplateId != null) templateIds.add(timer.timerTemplateId!);
        }

        final pImages = await (db.select(db.images)
              ..where((t) => t.pageId.equals(page.id)))
            .get();
        for (var img in pImages) {
          if (!exportedImageIds.contains(img.id)) {
            imagesJson.add(img.toJson());
            exportedImageIds.add(img.id);
          }
          if (img.positionId != null) positionIds.add(img.positionId!);
        }
      }
    }

    // Add school logos to images
    for (var school in schools) {
      if (school.logoImageId != null) {
        final img = await (db.select(db.images)
              ..where((t) => t.id.equals(school.logoImageId!)))
            .getSingleOrNull();
        if (img != null && !exportedImageIds.contains(img.id)) {
          imagesJson.add(img.toJson());
          exportedImageIds.add(img.id);
          if (img.positionId != null) positionIds.add(img.positionId!);
        }
      }
    }

    exportData['page'] = pagesJson;
    exportData['timer'] = timersJson;
    exportData['images'] = imagesJson;

    if (positionIds.isNotEmpty) {
      final positions = await (db.select(db.position)
            ..where((t) => t.id.isIn(positionIds.toList())))
          .get();
      exportData['position'] = positions.map((p) => p.toJson()).toList();
    } else {
      exportData['position'] = [];
    }

    if (templateIds.isNotEmpty) {
      final templates = await (db.select(db.timerTemplate)
            ..where((t) => t.id.isIn(templateIds.toList())))
          .get();
      exportData['timer_template'] = templates.map((t) => t.toJson()).toList();
      for (var t in templates) {
        if (t.dingAudioId != null) dingAudioIds.add(t.dingAudioId!);
      }

      final dingValues = await (db.select(db.dingValue)
            ..where((t) => t.timerTemplateId.isIn(templateIds.toList())))
          .get();
      exportData['ding_value'] = dingValues.map((dv) => dv.toJson()).toList();
    } else {
      exportData['timer_template'] = [];
      exportData['ding_value'] = [];
    }

    if (bgmIds.isNotEmpty) {
      final bgms = await (db.select(db.bgm)
            ..where((t) => t.id.isIn(bgmIds.toList())))
          .get();
      exportData['bgm'] = bgms.map((b) => b.toJson()).toList();
    } else {
      exportData['bgm'] = [];
    }

    if (dingAudioIds.isNotEmpty) {
      final dingAudios = await (db.select(db.dingAudio)
            ..where((t) => t.id.isIn(dingAudioIds.toList())))
          .get();
      exportData['ding_audio'] = dingAudios.map((da) => da.toJson()).toList();
    } else {
      exportData['ding_audio'] = [];
    }

    return exportData;
  }

  static Future<void> exportEvent(EventData event, String outputPath) async {
    final archive = Archive();
    final exportData = await exportEventToMap(event);

    // 1. JSON Data
    final jsonStr = jsonEncode(exportData);
    archive.addFile(ArchiveFile('event_data.json', jsonStr.length, utf8.encode(jsonStr)));

    // 2. Assets
    final supportDir = await getApplicationSupportDirectory();
    final dataDir = AppConfig.dataPath(supportDir.path);

    // Images
    for (var img in exportData['images']) {
      final oldId = img['id'];
      final imgName = img['image_name'];
      if (imgName != null) {
        final f = File(p.join(dataDir, 'images', '$oldId', imgName));
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          archive.addFile(ArchiveFile('YiHuaTimer/images/$oldId/$imgName', bytes.length, bytes));
        }
      }
    }

    // School Logos
    final schoolDir = Directory(p.join(dataDir, 'schools', '${event.id}'));
    if (await schoolDir.exists()) {
      await for (var entity in schoolDir.list(recursive: true)) {
        if (entity is File) {
          final relPath = p.relative(entity.path, from: p.join(dataDir, 'schools'));
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile('YiHuaTimer/schools/$relPath', bytes.length, bytes));
        }
      }
    }

    // BGMs
    final bgmDir = Directory(p.join(dataDir, 'bgm'));
    if (await bgmDir.exists()) {
      final bgmNames = (exportData['bgm'] as List).map((b) => b['bgm_name'] as String).toList();
      for (var name in bgmNames) {
        final f = File(p.join(bgmDir.path, name));
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          archive.addFile(ArchiveFile('YiHuaTimer/bgm/$name', bytes.length, bytes));
        }
      }
    }

    // Ding Audios
    final dingDir = Directory(p.join(dataDir, 'ding'));
    if (await dingDir.exists()) {
      final dingNames = (exportData['ding_audio'] as List).map((d) => d['ding_name'] as String).toList();
      for (var name in dingNames) {
        final f = File(p.join(dingDir.path, name));
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          archive.addFile(ArchiveFile('YiHuaTimer/ding/$name', bytes.length, bytes));
        }
      }
    }

    try {
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData != null) {
        final zipFile = File(outputPath);
        await zipFile.writeAsBytes(zipData);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> importEvent(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dataFile = archive.findFile('event_data.json');
    if (dataFile == null) throw Exception('Invalid event package: event_data.json missing');

    final jsonStr = utf8.decode(dataFile.content as List<int>);
    final Map<String, dynamic> importData = jsonDecode(jsonStr);

    final supportDir = await getApplicationSupportDirectory();
    final tempExtractDir = Directory(p.join(AppConfig.dataPath(supportDir.path),
        'temp_import_${DateTime.now().millisecondsSinceEpoch}'));

    try {
      for (var file in archive) {
        if (!file.isFile || file.name == 'event_data.json') continue;
        final segments = file.name.split('/').where((s) => s.isNotEmpty).toList();
        if (segments.isEmpty || segments.first.toLowerCase() != 'yihuatimer') continue;

        final destPath = p.joinAll([tempExtractDir.path, ...segments]);
        final destFile = File(destPath);
        if (!await destFile.parent.exists()) await destFile.parent.create(recursive: true);
        await destFile.writeAsBytes(file.content as List<int>);
      }

      await importEventData(importData, Directory(p.join(tempExtractDir.path, 'YiHuaTimer')));
    } finally {
      if (await tempExtractDir.exists()) await tempExtractDir.delete(recursive: true);
    }
  }

  static Future<void> importEventData(Map<String, dynamic> importData, Directory assetSourceDir) async {
    final supportDir = await getApplicationSupportDirectory();
    final currentDataDir = AppConfig.dataPath(supportDir.path);

    // 1. Assets Copy
    // Copy BGMs
    final srcBgm = Directory(p.join(assetSourceDir.path, 'bgm'));
    if (await srcBgm.exists()) {
      final destBgm = Directory(p.join(currentDataDir, 'bgm'));
      if (!await destBgm.exists()) await destBgm.create(recursive: true);
      await for (var srcFile in srcBgm.list(recursive: true)) {
        if (srcFile is File) {
          final destFile = File(p.join(destBgm.path, p.basename(srcFile.path)));
          if (!await destFile.exists()) await srcFile.copy(destFile.path);
        }
      }
    }

    // Copy Dings
    final srcDing = Directory(p.join(assetSourceDir.path, 'ding'));
    if (await srcDing.exists()) {
      final destDing = Directory(p.join(currentDataDir, 'ding'));
      if (!await destDing.exists()) await destDing.create(recursive: true);
      await for (var srcFile in srcDing.list(recursive: true)) {
        if (srcFile is File) {
          final destFile = File(p.join(destDing.path, p.basename(srcFile.path)));
          if (!await destFile.exists()) await srcFile.copy(destFile.path);
        }
      }
    }

    // 2. Database Import
    await database.transaction(() async {
      final eventData = importData['event'];
      if (eventData == null) throw Exception('Event details missing in JSON');
      final oldEventId = (eventData['id'] as num).toInt();

      final Map<int, int> positionIdMap = {};
      final Map<int, int> schoolIdMap = {};
      final Map<int, int> folderIdMap = {};
      final Map<int, int> flowIdMap = {};
      final Map<int, int> pageIdMap = {};
      final Map<int, int> dingAudioIdMap = {};
      final Map<int, int> templateIdMap = {};
      final Map<int, int> bgmIdMap = {};
      final Map<int, int> imageIdMap = {};

      // Positions
      for (var posJson in importData['position'] ?? []) {
        final oldId = (posJson['id'] as num).toInt();
        final newId = await database.into(database.position).insert(PositionCompanion.insert(
              xpos: drift.Value((posJson['xpos'] as num?)?.toDouble() ?? 0.0),
              ypos: drift.Value((posJson['ypos'] as num?)?.toDouble() ?? 0.0),
              size: drift.Value((posJson['size'] as num?)?.toDouble() ?? 1.0),
            ));
        positionIdMap[oldId] = newId;
      }

      // BGMs
      for (var bgmJson in importData['bgm'] ?? []) {
        final oldId = (bgmJson['id'] as num).toInt();
        final name = bgmJson['bgm_name']?.toString() ?? 'Unknown BGM';
        final existing = await (database.select(database.bgm)..where((t) => t.bgmName.equals(name))).getSingleOrNull();
        if (existing == null) {
          final newId = await database.into(database.bgm).insert(BgmCompanion.insert(bgmName: name));
          bgmIdMap[oldId] = newId;
        } else {
          bgmIdMap[oldId] = existing.id;
        }
      }

      // Ding Audios
      for (var daJson in importData['ding_audio'] ?? []) {
        final oldId = (daJson['id'] as num).toInt();
        final name = daJson['ding_name']?.toString() ?? 'Unknown Ding';
        final existing = await (database.select(database.dingAudio)..where((t) => t.dingName.equals(name))).getSingleOrNull();
        if (existing == null) {
          final newId = await database.into(database.dingAudio).insert(DingAudioCompanion.insert(dingName: name));
          dingAudioIdMap[oldId] = newId;
        } else {
          dingAudioIdMap[oldId] = existing.id;
        }
      }

      // Templates
      for (var tplJson in importData['timer_template'] ?? []) {
        final oldId = (tplJson['id'] as num).toInt();
        final templateName = tplJson['template_name']?.toString();
        final oldAudioId = tplJson['ding_audio_id'];
        final newAudioId = oldAudioId != null ? dingAudioIdMap[oldAudioId] : null;

        final importedDvs = (importData['ding_value'] as List? ?? [])
            .where((dv) => (dv['timer_template_id'] as num).toInt() == oldId)
            .toList();

        int? existingTplId;
        final potentialTemplates = await (database.select(database.timerTemplate)
              ..where((t) => t.templateName.equals(templateName ?? ''))
              ..where((t) => newAudioId == null ? t.dingAudioId.isNull() : t.dingAudioId.equals(newAudioId)))
            .get();

        for (var pot in potentialTemplates) {
          final potDvs = await (database.select(database.dingValue)..where((t) => t.timerTemplateId.equals(pot.id))).get();
          if (potDvs.length == importedDvs.length) {
            bool allMatch = true;
            for (var impDv in importedDvs) {
              if (!potDvs.any((pd) => pd.dingTime == impDv['ding_time']?.toString() && pd.dingAmount == (impDv['ding_amount'] as num?)?.toInt())) {
                allMatch = false; break;
              }
            }
            if (allMatch) { existingTplId = pot.id; break; }
          }
        }

        if (existingTplId != null) {
          templateIdMap[oldId] = existingTplId;
        } else {
          final newId = await database.into(database.timerTemplate).insert(TimerTemplateCompanion.insert(
                templateName: drift.Value(templateName),
                dingAudioId: drift.Value(newAudioId),
              ));
          templateIdMap[oldId] = newId;
          for (var dvJson in importedDvs) {
            await database.into(database.dingValue).insert(DingValueCompanion.insert(
                  dingTime: drift.Value(dvJson['ding_time']?.toString()),
                  dingAmount: drift.Value((dvJson['ding_amount'] as num?)?.toInt() ?? 1),
                  timerTemplateId: drift.Value(newId),
                ));
          }
        }
      }

      // Event
      final newEventId = await database.into(database.event).insert(EventCompanion.insert(
            eventName: eventData['event_name']?.toString() ?? '导入的赛事',
            eventDesc: drift.Value(eventData['event_desc']?.toString()),
            startDate: drift.Value(_safeParseDate(eventData['start_date'])),
            endDate: drift.Value(_safeParseDate(eventData['end_date'])),
            teamNum: drift.Value((eventData['team_num'] as num?)?.toInt()),
            remark: drift.Value(eventData['remark']?.toString()),
          ));

      // Images
      final srcImgDir = Directory(p.join(assetSourceDir.path, 'images', '$oldEventId'));
      final destImgDir = Directory(p.join(currentDataDir, 'images', '$newEventId'));
      if (await srcImgDir.exists()) {
        await _recursiveCopy(srcImgDir, destImgDir);
      }

      for (var imgJson in importData['images'] ?? []) {
        final oldId = (imgJson['id'] as num).toInt();
        final oldPosId = imgJson['position_id'];
        final newId = await database.into(database.images).insert(ImagesCompanion.insert(
              imageName: drift.Value(imgJson['image_name']?.toString()),
              imageType: drift.Value(imgJson['image_type']?.toString()),
              positionId: drift.Value(oldPosId != null ? positionIdMap[(oldPosId as num).toInt()] : null),
            ));
        imageIdMap[oldId] = newId;
      }

      // Schools
      final srcSchoolDir = Directory(p.join(assetSourceDir.path, 'schools', '$oldEventId'));
      final destSchoolDir = Directory(p.join(currentDataDir, 'schools', '$newEventId'));
      if (await srcSchoolDir.exists()) {
        await _recursiveCopy(srcSchoolDir, destSchoolDir);
      }

      for (var scJson in importData['school'] ?? []) {
        final oldId = (scJson['id'] as num).toInt();
        final oldLogoId = scJson['logo_image_id'];
        final newId = await database.into(database.school).insert(SchoolCompanion.insert(
              schoolName: scJson['school_name']?.toString() ?? '',
              eventId: newEventId,
              logoImageId: drift.Value(oldLogoId != null ? imageIdMap[(oldLogoId as num).toInt()] : null),
            ));
        schoolIdMap[oldId] = newId;
      }

      // Folders
      for (var ffJson in importData['flow_folder'] ?? []) {
        final oldId = (ffJson['id'] as num).toInt();
        final newId = await database.into(database.flowFolder).insert(FlowFolderCompanion.insert(
              folderName: ffJson['folder_name']?.toString() ?? '',
              eventId: newEventId,
              folderPosition: (ffJson['folder_position'] as num).toInt(),
            ));
        folderIdMap[oldId] = newId;
      }

      // Flows
      for (var flJson in importData['flow'] ?? []) {
        final oldId = (flJson['id'] as num).toInt();
        final oldFolderId = flJson['folder_id'];
        final oldSchoolAId = flJson['school_a_id'];
        final oldSchoolBId = flJson['school_b_id'];
        final newId = await database.into(database.flow).insert(FlowCompanion.insert(
              flowName: drift.Value(flJson['flow_name']?.toString()),
              fontName: drift.Value(flJson['font_name']?.toString()),
              sectionFontName: drift.Value(flJson['section_font_name']?.toString()),
              timerFontName: drift.Value(flJson['timer_font_name']?.toString()),
              frontpageName: drift.Value(flJson['frontpage_name']?.toString()),
              backgroundName: drift.Value(flJson['background_name']?.toString()),
              eventId: drift.Value(newEventId),
              flowPosition: drift.Value((flJson['flow_position'] as num?)?.toInt()),
              folderId: drift.Value(oldFolderId != null ? folderIdMap[(oldFolderId as num).toInt()] : null),
              schoolAId: drift.Value(oldSchoolAId != null ? schoolIdMap[(oldSchoolAId as num).toInt()] : null),
              schoolBId: drift.Value(oldSchoolBId != null ? schoolIdMap[(oldSchoolBId as num).toInt()] : null),
              positionConfig: drift.Value(flJson['position_config']?.toString()),
            ));
        flowIdMap[oldId] = newId;
      }

      // Pages
      for (var pgJson in importData['page'] ?? []) {
        final oldId = (pgJson['id'] as num).toInt();
        final oldBgmId = pgJson['bgm_id'];
        final oldFlowId = pgJson['flow_id'];
        final oldSecPosId = pgJson['section_position_id'];
        final oldSaPosId = pgJson['school_a_position_id'];
        final oldSbPosId = pgJson['school_b_position_id'];

        final newId = await database.into(database.page).insert(PageCompanion.insert(
              pageName: drift.Value(pgJson['page_name']?.toString()),
              sectionName: drift.Value(pgJson['section_name']?.toString()),
              bgmId: drift.Value(oldBgmId != null ? bgmIdMap[(oldBgmId as num).toInt()] : null),
              pageTypeId: drift.Value(pgJson['page_type_id']?.toString()),
              hotkeyValue: drift.Value(pgJson['hotkey_value']?.toString()),
              flowId: drift.Value(oldFlowId != null ? flowIdMap[(oldFlowId as num).toInt()] : null),
              pagePosition: drift.Value((pgJson['page_position'] as num?)?.toInt() ?? 0),
              sectionXpos: drift.Value((pgJson['section_xpos'] as num?)?.toDouble()),
              sectionYpos: drift.Value((pgJson['section_ypos'] as num?)?.toDouble()),
              sectionScale: drift.Value((pgJson['section_scale'] as num?)?.toDouble()),
              sectionFontName: drift.Value(pgJson['section_font_name']?.toString()),
              timerFontName: drift.Value(pgJson['timer_font_name']?.toString()),
              useFrontpage: drift.Value(pgJson['use_frontpage'] as bool? ?? false),
              sectionPositionId: drift.Value(oldSecPosId != null ? positionIdMap[(oldSecPosId as num).toInt()] : null),
              isDefaultPage: drift.Value(pgJson['is_default_page'] as bool? ?? false),
              schoolAPositionId: drift.Value(oldSaPosId != null ? positionIdMap[(oldSaPosId as num).toInt()] : null),
              schoolBPositionId: drift.Value(oldSbPosId != null ? positionIdMap[(oldSbPosId as num).toInt()] : null),
              inheritTimerFromId: drift.Value(pgJson['inherit_timer_from_id'] != null ? pageIdMap[(pgJson['inherit_timer_from_id'] as num).toInt()] : null),
              inheritTimerRangeEnabled: drift.Value(pgJson['inherit_timer_range_enabled'] as bool? ?? false),
              inheritTimerMin: drift.Value((pgJson['inherit_timer_min'] as num?)?.toInt()),
              inheritTimerMax: drift.Value((pgJson['inherit_timer_max'] as num?)?.toInt()),
            ));
        pageIdMap[oldId] = newId;

        // Timers for this page
        for (var tJson in (importData['timer'] as List? ?? []).where((t) => (t['page_id'] as num).toInt() == oldId)) {
          final oldPosId = tJson['position_id'];
          final oldTplId = tJson['timer_template_id'];
          await database.into(database.timer).insert(TimerCompanion.insert(
                pageId: drift.Value(newId),
                startTime: drift.Value(tJson['start_time']?.toString()),
                timerType: drift.Value(tJson['timer_type']?.toString()),
                positionId: drift.Value(oldPosId != null ? positionIdMap[(oldPosId as num).toInt()] : null),
                timerTemplateId: drift.Value(oldTplId != null ? templateIdMap[(oldTplId as num).toInt()] : null),
              ));
        }

        // Images belonging to this page
        for (var imgJson in (importData['images'] as List? ?? []).where((i) => i['page_id'] != null && (i['page_id'] as num).toInt() == oldId)) {
          final newImgId = imageIdMap[(imgJson['id'] as num).toInt()];
          if (newImgId != null) {
            await (database.update(database.images)..where((t) => t.id.equals(newImgId))).write(ImagesCompanion(pageId: drift.Value(newId)));
          }
        }
      }
    });
  }

  static DateTime? _safeParseDate(dynamic val) {
    if (val == null || val.toString().isEmpty || val.toString() == 'null') return null;
    if (val is int) {
      int finalValue = val; String s = val.abs().toString();
      if (s.length <= 10) finalValue = val * 1000;
      else if (s.length > 13) finalValue = int.parse(s.substring(0, 13)) * (val < 0 ? -1 : 1);
      return DateTime.fromMillisecondsSinceEpoch(finalValue, isUtc: true).toLocal();
    }
    try { return DateTime.parse(val.toString()); } catch (_) { return null; }
  }

  static Future<void> _recursiveCopy(Directory source, Directory destination) async {
    if (!await destination.exists()) await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      final destPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) await _recursiveCopy(entity, Directory(destPath));
      else if (entity is File) await entity.copy(destPath);
    }
  }
}
