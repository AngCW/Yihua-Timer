import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../main.dart';

class EventTransfer {
  static Future<void> exportEvent(EventData event, String outputPath) async {
    final archive = Archive();
    final Map<String, dynamic> exportData = {};

    // 1. Fetch all database records related to the event
    exportData['event'] = event.toJson();

    final schools = await (database.select(database.school)
          ..where((t) => t.eventId.equals(event.id)))
        .get();
    exportData['school'] = schools.map((s) => s.toJson()).toList();

    final flowFolders = await (database.select(database.flowFolder)
          ..where((t) => t.eventId.equals(event.id)))
        .get();
    exportData['flow_folder'] = flowFolders.map((ff) => ff.toJson()).toList();

    final flows = await (database.select(database.flow)
          ..where((t) => t.eventId.equals(event.id)))
        .get();
    exportData['flow'] = flows.map((f) => f.toJson()).toList();

    final List<Map<String, dynamic>> pagesJson = [];
    final List<Map<String, dynamic>> timersJson = [];
    final List<Map<String, dynamic>> imagesJson = [];
    final Set<int> positionIds = {};
    final Set<int> templateIds = {};
    final Set<int> bgmIds = {};

    for (var flow in flows) {
      final pages = await (database.select(database.page)
            ..where((t) => t.flowId.equals(flow.id)))
          .get();
      for (var page in pages) {
        pagesJson.add(page.toJson());
        if (page.sectionPositionId != null)
          positionIds.add(page.sectionPositionId!);
        if (page.schoolAPositionId != null)
          positionIds.add(page.schoolAPositionId!);
        if (page.schoolBPositionId != null)
          positionIds.add(page.schoolBPositionId!);
        if (page.bgmId != null) bgmIds.add(page.bgmId!);

        final timers = await (database.select(database.timer)
              ..where((t) => t.pageId.equals(page.id)))
            .get();
        for (var timer in timers) {
          timersJson.add(timer.toJson());
          if (timer.positionId != null) positionIds.add(timer.positionId!);
          if (timer.timerTemplateId != null)
            templateIds.add(timer.timerTemplateId!);
        }

        final pImages = await (database.select(database.images)
              ..where((t) => t.pageId.equals(page.id)))
            .get();
        for (var img in pImages) {
          imagesJson.add(img.toJson());
          if (img.positionId != null) positionIds.add(img.positionId!);
        }
      }
    }

    // Add school logos to images
    for (var school in schools) {
      if (school.logoImageId != null) {
        final img = await (database.select(database.images)
              ..where((t) => t.id.equals(school.logoImageId!)))
            .getSingleOrNull();
        if (img != null) {
          imagesJson.add(img.toJson());
          if (img.positionId != null) positionIds.add(img.positionId!);
        }
      }
    }

    exportData['page'] = pagesJson;
    exportData['timer'] = timersJson;
    exportData['images'] = imagesJson;

    if (positionIds.isNotEmpty) {
      final positions = await (database.select(database.position)
            ..where((t) => t.id.isIn(positionIds.toList())))
          .get();
      exportData['position'] = positions.map((p) => p.toJson()).toList();
    } else {
      exportData['position'] = [];
    }

    // Collect templates and their values/audio
    final Set<int> dingAudioIds = {};
    if (templateIds.isNotEmpty) {
      final templates = await (database.select(database.timerTemplate)
            ..where((t) => t.id.isIn(templateIds.toList())))
          .get();
      exportData['timer_template'] = templates.map((t) => t.toJson()).toList();
      for (var t in templates) {
        if (t.dingAudioId != null) dingAudioIds.add(t.dingAudioId!);
      }

      final dingValues = await (database.select(database.dingValue)
            ..where((t) => t.timerTemplateId.isIn(templateIds.toList())))
          .get();
      exportData['ding_value'] = dingValues.map((dv) => dv.toJson()).toList();
    } else {
      exportData['timer_template'] = [];
      exportData['ding_value'] = [];
    }

    if (bgmIds.isNotEmpty) {
      final bgms = await (database.select(database.bgm)
            ..where((t) => t.id.isIn(bgmIds.toList())))
          .get();
      exportData['bgm'] = bgms.map((b) => b.toJson()).toList();
    } else {
      exportData['bgm'] = [];
    }

    if (dingAudioIds.isNotEmpty) {
      final dingAudios = await (database.select(database.dingAudio)
            ..where((t) => t.id.isIn(dingAudioIds.toList())))
          .get();
      exportData['ding_audio'] = dingAudios.map((da) => da.toJson()).toList();
    } else {
      exportData['ding_audio'] = [];
    }

    // 2. Wrap JSON in a file
    final jsonStr = jsonEncode(exportData);
    archive.addFile(
        ArchiveFile('event_data.json', jsonStr.length, utf8.encode(jsonStr)));

    // 3. Identify and pack physical files
    final supportDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(
        p.join(supportDir.path, 'YiHuaTimer', 'images', '${event.id}'));
    final bgmDir = Directory(p.join(supportDir.path, 'YiHuaTimer', 'bgm'));
    final dingDir = Directory(p.join(supportDir.path, 'YiHuaTimer', 'ding'));

    // Pack event-specific images (relative to supportDir so path includes YiHuaTimer/images/<id>/)
    if (await imagesDir.exists()) {
      await for (var file in imagesDir.list(recursive: true)) {
        if (file is File) {
          // Use supportDir as base so zip path = YiHuaTimer/images/<id>/filename
          final relativePath = p
              .relative(file.path, from: supportDir.path)
              .replaceAll('\\', '/');
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        }
      }
    }

    // Pack school logos (relative to supportDir so path includes YiHuaTimer/schools/<id>/)
    final schoolsDir = Directory(
        p.join(supportDir.path, 'YiHuaTimer', 'schools', '${event.id}'));
    if (await schoolsDir.exists()) {
      await for (var file in schoolsDir.list(recursive: true)) {
        if (file is File) {
          final relativePath = p
              .relative(file.path, from: supportDir.path)
              .replaceAll('\\', '/');
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
        }
      }
    }

    // Pack referenced BGMs
    final List<String> bgmNames = (exportData['bgm'] as List)
        .map((b) => b['bgm_name'] as String)
        .toList();
    for (var name in bgmNames) {
      final f = File(p.join(bgmDir.path, name));
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        // Always use forward slashes in zip paths
        archive
            .addFile(ArchiveFile('YiHuaTimer/bgm/$name', bytes.length, bytes));
      }
    }

    // Pack referenced Ding Audios
    final List<String> dingNames = (exportData['ding_audio'] as List)
        .map((da) => da['ding_name'] as String)
        .toList();
    for (var name in dingNames) {
      final f = File(p.join(dingDir.path, name));
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        archive
            .addFile(ArchiveFile('YiHuaTimer/ding/$name', bytes.length, bytes));
      }
    }

    try {
      // 4. Save Zip
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);
      if (zipData != null) {
        final zipFile = File(outputPath);
        await zipFile.writeAsBytes(zipData);
      }
      print('Export successful');
    } catch (e, stack) {
      print('Error during zip encoding or saving: $e');
      print(stack);
      rethrow;
    }
  }

  static Future<void> importEvent(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Find and parse event_data.json
    final dataFile = archive.findFile('event_data.json');
    if (dataFile == null) {
      print('Error: event_data.json not found in zip');
      throw Exception('Invalid event package: event_data.json missing');
    }

    final jsonStr = utf8.decode(dataFile.content as List<int>);
    final Map<String, dynamic> importData = jsonDecode(jsonStr);

    final supportDir = await getApplicationSupportDirectory();
    final tempExtractDir = Directory(p.join(supportDir.path, 'YiHuaTimer',
        'temp_import_${DateTime.now().millisecondsSinceEpoch}'));

    try {
      // 2. Extract files into temp directory
      for (var file in archive) {
        if (!file.isFile || file.name == 'event_data.json') continue;

        // Normalize zip path (forward slashes) to OS path segments
        final segments =
            file.name.split('/').where((s) => s.isNotEmpty).toList();

        // Safety check: first segment must be 'YiHuaTimer' to prevent path traversal
        if (segments.isEmpty || segments.first != 'YiHuaTimer') {
          print('Skipping unexpected archive entry: ${file.name}');
          continue;
        }

        final destPath = p.joinAll([tempExtractDir.path, ...segments]);
        final destFile = File(destPath);
        if (!await destFile.parent.exists()) {
          await destFile.parent.create(recursive: true);
        }
        await destFile.writeAsBytes(file.content as List<int>);
      }

      // Process bgm and ding (ignore if exist)
      final tempBgm =
          Directory(p.join(tempExtractDir.path, 'YiHuaTimer', 'bgm'));
      if (await tempBgm.exists()) {
        final realBgm = Directory(p.join(supportDir.path, 'YiHuaTimer', 'bgm'));
        if (!await realBgm.exists()) await realBgm.create(recursive: true);
        await for (var srcFile in tempBgm.list(recursive: true)) {
          if (srcFile is File) {
            final destFile =
                File(p.join(realBgm.path, p.basename(srcFile.path)));
            if (!await destFile.exists()) {
              await srcFile.copy(destFile.path);
            }
          }
        }
      }

      final tempDing =
          Directory(p.join(tempExtractDir.path, 'YiHuaTimer', 'ding'));
      if (await tempDing.exists()) {
        final realDing =
            Directory(p.join(supportDir.path, 'YiHuaTimer', 'ding'));
        if (!await realDing.exists()) await realDing.create(recursive: true);
        await for (var srcFile in tempDing.list(recursive: true)) {
          if (srcFile is File) {
            final destFile =
                File(p.join(realDing.path, p.basename(srcFile.path)));
            if (!await destFile.exists()) {
              await srcFile.copy(destFile.path);
            }
          }
        }
      }

      // 3. Database Import with ID Re-mapping
      await database.transaction(() async {
        final eventData = importData['event'];
        if (eventData == null) throw Exception('Event details missing in JSON');
        final oldEventId = (eventData['id'] as num).toInt();

        // I’ll use a map to keep track of oldId -> newId for each table
        final Map<int, int> positionIdMap = {};
        final Map<int, int> schoolIdMap = {};
        final Map<int, int> folderIdMap = {};
        final Map<int, int> flowIdMap = {};
        final Map<int, int> pageIdMap = {};
        final Map<int, int> dingAudioIdMap = {};
        final Map<int, int> templateIdMap = {};
        final Map<int, int> bgmIdMap = {};

        // Positions first as many tables reference them
        for (var posJson in importData['position'] ?? []) {
          final oldId = (posJson['id'] as num).toInt();
          final newId = await database
              .into(database.position)
              .insert(PositionCompanion.insert(
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
          final existingList = await (database.select(database.bgm)
                ..where((t) => t.bgmName.equals(name)))
              .get();
          final existing = existingList.isNotEmpty ? existingList.first : null;
          if (existing == null) {
            final newId = await database
                .into(database.bgm)
                .insert(BgmCompanion.insert(bgmName: name));
            bgmIdMap[oldId] = newId;
          } else {
            bgmIdMap[oldId] = existing.id;
          }
        }

        // Ding Audios
        for (var daJson in importData['ding_audio'] ?? []) {
          final oldId = (daJson['id'] as num).toInt();
          final name = daJson['ding_name']?.toString() ?? 'Unknown Ding';
          final existingList = await (database.select(database.dingAudio)
                ..where((t) => t.dingName.equals(name)))
              .get();
          final existing = existingList.isNotEmpty ? existingList.first : null;
          if (existing == null) {
            final newId = await database
                .into(database.dingAudio)
                .insert(DingAudioCompanion.insert(dingName: name));
            dingAudioIdMap[oldId] = newId;
          } else {
            dingAudioIdMap[oldId] = existing.id;
          }
        }

        // Timer Templates with Similarity Check
        for (var tplJson in importData['timer_template'] ?? []) {
          final oldId = (tplJson['id'] as num).toInt();
          final oldAudioId = tplJson['ding_audio_id'];
          final newAudioId = oldAudioId != null ? dingAudioIdMap[oldAudioId] : null;
          final templateName = tplJson['template_name']?.toString();
          
          // Collect imported ding values for this specific template
          final importedDvs = (importData['ding_value'] as List? ?? [])
              .where((dv) => (dv['timer_template_id'] as num).toInt() == oldId)
              .toList();

          int? existingTplId;

          // Check for existing identical template
          final potentialTemplates = await (database.select(database.timerTemplate)
                ..where((t) => t.templateName.equals(templateName ?? ''))
                ..where((t) => newAudioId == null 
                    ? t.dingAudioId.isNull() 
                    : t.dingAudioId.equals(newAudioId)))
              .get();

          for (var pot in potentialTemplates) {
            final potDvs = await (database.select(database.dingValue)
                  ..where((t) => t.timerTemplateId.equals(pot.id)))
                .get();
            
            if (potDvs.length == importedDvs.length) {
              bool allMatch = true;
              for (var impDv in importedDvs) {
                final match = potDvs.any((pd) => 
                  pd.dingTime == impDv['ding_time']?.toString() && 
                  pd.dingAmount == (impDv['ding_amount'] as num?)?.toInt());
                if (!match) {
                  allMatch = false;
                  break;
                }
              }
              if (allMatch) {
                existingTplId = pot.id;
                break;
              }
            }
          }

          if (existingTplId != null) {
            templateIdMap[oldId] = existingTplId;
          } else {
            // No identical template found, insert new one
            final newId = await database
                .into(database.timerTemplate)
                .insert(TimerTemplateCompanion.insert(
                  templateName: drift.Value(templateName),
                  dingAudioId: drift.Value(newAudioId),
                ));
            templateIdMap[oldId] = newId;

            // Insert new ding values only for this new template
            for (var dvJson in importedDvs) {
              await database
                  .into(database.dingValue)
                  .insert(DingValueCompanion.insert(
                    dingTime: drift.Value(dvJson['ding_time']?.toString()),
                    dingAmount: drift.Value((dvJson['ding_amount'] as num?)?.toInt() ?? 1),
                    timerTemplateId: drift.Value(newId),
                  ));
            }
          }
        }

        // The Event itself
        final eventJson = importData['event'];

        DateTime? safeParseDate(dynamic val) {
          if (val == null || val.toString().isEmpty || val.toString() == 'null') {
            return null;
          }
          if (val is int) {
            int finalValue = val;
            String s = val.abs().toString();
            if (s.length <= 10) {
              finalValue = val * 1000;
            } else if (s.length > 13) {
              String trimmed = s.substring(0, 13);
              finalValue = int.parse(trimmed) * (val < 0 ? -1 : 1);
            }
            return DateTime.fromMillisecondsSinceEpoch(finalValue, isUtc: true).toLocal();
          }
          try {
            return DateTime.parse(val.toString());
          } catch (e) {
            print('Warning: Failed to parse date "$val": $e');
            return null;
          }
        }

        final newEventId = await database
            .into(database.event)
            .insert(EventCompanion.insert(
              eventName: eventJson['event_name']?.toString() ?? '导入的赛事',
              eventDesc: drift.Value(eventJson['event_desc']?.toString()),
              startDate: drift.Value(safeParseDate(eventJson['start_date'])),
              endDate: drift.Value(safeParseDate(eventJson['end_date'])),
              teamNum: drift.Value((eventJson['team_num'] as num?)?.toInt()),
              remark: drift.Value(eventJson['remark']?.toString()),
            ));

        // After we have the new Event ID, we should rename the extracted images directory from temp
        final extractedImageDir = Directory(
            p.join(tempExtractDir.path, 'YiHuaTimer', 'images', '$oldEventId'));
        final newImageDir = Directory(
            p.join(supportDir.path, 'YiHuaTimer', 'images', '$newEventId'));
        if (await extractedImageDir.exists()) {
          if (await newImageDir.exists())
            await newImageDir.delete(recursive: true);
          if (!await newImageDir.parent.exists())
            await newImageDir.parent.create(recursive: true);
          await extractedImageDir.rename(newImageDir.path);
        }

        // After we have the new Event ID, we should rename the extracted schools directory from temp
        final extractedSchoolDir = Directory(p.join(
            tempExtractDir.path, 'YiHuaTimer', 'schools', '$oldEventId'));
        final newSchoolDir = Directory(
            p.join(supportDir.path, 'YiHuaTimer', 'schools', '$newEventId'));
        if (await extractedSchoolDir.exists()) {
          if (await newSchoolDir.exists())
            await newSchoolDir.delete(recursive: true);
          if (!await newSchoolDir.parent.exists())
            await newSchoolDir.parent.create(recursive: true);
          await extractedSchoolDir.rename(newSchoolDir.path);
        }

        // Images (Need to remap positions and page_id later)
        final Map<int, int> imageIdMap = {};
        for (var imgJson in importData['images'] ?? []) {
          final oldId = (imgJson['id'] as num).toInt();
          final oldPosId = imgJson['position_id'];
          final newId = await database
              .into(database.images)
              .insert(ImagesCompanion.insert(
                imageName: drift.Value(imgJson['image_name']?.toString()),
                imageType: drift.Value(imgJson['image_type']?.toString()),
                positionId: drift.Value(oldPosId != null
                    ? positionIdMap[(oldPosId as num).toInt()]
                    : null),
              ));
          imageIdMap[oldId] = newId;
        }

        // Schools
        for (var scJson in importData['school'] ?? []) {
          final oldId = (scJson['id'] as num).toInt();
          final oldLogoId = scJson['logo_image_id'];
          final newId = await database
              .into(database.school)
              .insert(SchoolCompanion.insert(
                schoolName: scJson['school_name']?.toString() ?? '',
                eventId: newEventId,
                logoImageId: drift.Value(oldLogoId != null
                    ? imageIdMap[(oldLogoId as num).toInt()]
                    : null),
              ));
          schoolIdMap[oldId] = newId;
        }

        // Flow Folders
        for (var ffJson in importData['flow_folder'] ?? []) {
          final oldId = (ffJson['id'] as num).toInt();
          final newId = await database
              .into(database.flowFolder)
              .insert(FlowFolderCompanion.insert(
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
          final newId =
              await database.into(database.flow).insert(FlowCompanion.insert(
                    flowName: drift.Value(flJson['flow_name']?.toString()),
                    fontName: drift.Value(flJson['font_name']?.toString()),
                    sectionFontName:
                        drift.Value(flJson['section_font_name']?.toString()),
                    timerFontName:
                        drift.Value(flJson['timer_font_name']?.toString()),
                    frontpageName:
                        drift.Value(flJson['frontpage_name']?.toString()),
                    backgroundName:
                        drift.Value(flJson['background_name']?.toString()),
                    eventId: drift.Value(newEventId),
                    flowPosition:
                        drift.Value((flJson['flow_position'] as num?)?.toInt()),
                    folderId: drift.Value(oldFolderId != null
                        ? folderIdMap[(oldFolderId as num).toInt()]
                        : null),
                    schoolAId: drift.Value(oldSchoolAId != null
                        ? schoolIdMap[(oldSchoolAId as num).toInt()]
                        : null),
                    schoolBId: drift.Value(oldSchoolBId != null
                        ? schoolIdMap[(oldSchoolBId as num).toInt()]
                        : null),
                    positionConfig:
                        drift.Value(flJson['position_config']?.toString()),
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

          final newId = await database
              .into(database.page)
              .insert(PageCompanion.insert(
                pageName: drift.Value(pgJson['page_name']?.toString()),
                sectionName: drift.Value(pgJson['section_name']?.toString()),
                bgmId: drift.Value(oldBgmId != null
                    ? bgmIdMap[(oldBgmId as num).toInt()]
                    : null),
                pageTypeId: drift.Value(pgJson['page_type_id']?.toString()),
                hotkeyValue: drift.Value(pgJson['hotkey_value']?.toString()),
                flowId: drift.Value(oldFlowId != null
                    ? flowIdMap[(oldFlowId as num).toInt()]
                    : null),
                pagePosition: drift.Value(
                    (pgJson['page_position'] as num?)?.toInt() ?? 0),
                sectionXpos:
                    drift.Value((pgJson['section_xpos'] as num?)?.toDouble()),
                sectionYpos:
                    drift.Value((pgJson['section_ypos'] as num?)?.toDouble()),
                sectionScale:
                    drift.Value((pgJson['section_scale'] as num?)?.toDouble()),
                sectionFontName:
                    drift.Value(pgJson['section_font_name']?.toString()),
                timerFontName:
                    drift.Value(pgJson['timer_font_name']?.toString()),
                useFrontpage:
                    drift.Value(pgJson['use_frontpage'] as bool? ?? false),
                sectionPositionId: drift.Value(oldSecPosId != null
                    ? positionIdMap[(oldSecPosId as num).toInt()]
                    : null),
                isDefaultPage:
                    drift.Value(pgJson['is_default_page'] as bool? ?? false),
                schoolAPositionId: drift.Value(oldSaPosId != null
                    ? positionIdMap[(oldSaPosId as num).toInt()]
                    : null),
                schoolBPositionId: drift.Value(oldSbPosId != null
                    ? positionIdMap[(oldSbPosId as num).toInt()]
                    : null),
              ));
          pageIdMap[oldId] = newId;

          // Update images that belong to this page
          for (var imgJson in importData['images'] ?? []) {
            final oldPageIdOnImg = imgJson['page_id'];
            if (oldPageIdOnImg != null &&
                (oldPageIdOnImg as num).toInt() == oldId) {
              final newImgId = imageIdMap[(imgJson['id'] as num).toInt()];
              if (newImgId != null) {
                await (database.update(database.images)
                      ..where((t) => t.id.equals(newImgId)))
                    .write(ImagesCompanion(
                  pageId: drift.Value(newId),
                ));
              }
            }
          }
        }

        // Timers
        for (var tmJson in importData['timer'] ?? []) {
          final oldTplId = tmJson['timer_template_id'];
          final oldPageId = tmJson['page_id'];
          final oldPosId = tmJson['position_id'];

          await database.into(database.timer).insert(TimerCompanion.insert(
                timerTemplateId: drift.Value(oldTplId != null
                    ? templateIdMap[(oldTplId as num).toInt()]
                    : null),
                startTime: drift.Value(tmJson['start_time']?.toString()),
                timerType: drift.Value(tmJson['timer_type']?.toString()),
                pageId: drift.Value(oldPageId != null
                    ? pageIdMap[(oldPageId as num).toInt()]
                    : null),
                xpos: drift.Value((tmJson['xpos'] as num?)?.toDouble() ?? 0.0),
                ypos: drift.Value((tmJson['ypos'] as num?)?.toDouble() ?? 0.0),
                scale:
                    drift.Value((tmJson['scale'] as num?)?.toDouble() ?? 1.0),
                positionId: drift.Value(oldPosId != null
                    ? positionIdMap[(oldPosId as num).toInt()]
                    : null),
              ));
        }
      });
    } catch (e, stack) {
      print('Error during import process: $e');
      print(stack);
      rethrow;
    } finally {
      if (await tempExtractDir.exists()) {
        await tempExtractDir.delete(recursive: true);
      }
    }
  }
}
