import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../main.dart'; // For database global

class FlowUtils {
  static Future<FlowData> duplicateFlow(FlowData flow, int eventId,
      {int? folderId, int? position}) async {
    final flows = await (database.select(database.flow)
          ..where((t) => t.eventId.equals(eventId))
          ..where((t) => folderId != null
              ? t.folderId.equals(folderId)
              : t.folderId.isNull()))
        .get();

    final newPosition = position ?? (flows.length + 1);

    final newFlow = await database.into(database.flow).insertReturning(
          FlowCompanion.insert(
            flowName: drift.Value('${flow.flowName} (副本)'),
            eventId: drift.Value(eventId),
            flowPosition: drift.Value(newPosition),
            folderId: drift.Value(folderId),
            fontName: drift.Value(flow.fontName),
            sectionFontName: drift.Value(flow.sectionFontName),
            timerFontName: drift.Value(flow.timerFontName),
            frontpageName: drift.Value(flow.frontpageName),
            backgroundName: drift.Value(flow.backgroundName),
            sectionFontColor: drift.Value(flow.sectionFontColor),
            timerFontColor: drift.Value(flow.timerFontColor),
          ),
        );

    final pages = await (database.select(database.page)
          ..where((t) => t.flowId.equals(flow.id)))
        .get();

    for (final page in pages) {
      // Deep copy positions if they exist
      int? newSecPosId;
      if (page.sectionPositionId != null) {
        final oldPos = await (database.select(database.position)
              ..where((t) => t.id.equals(page.sectionPositionId!)))
            .getSingleOrNull();
        if (oldPos != null) {
          newSecPosId = await database.into(database.position).insert(
                PositionCompanion.insert(
                  xpos: drift.Value(oldPos.xpos),
                  ypos: drift.Value(oldPos.ypos),
                  size: drift.Value(oldPos.size),
                ),
              );
        }
      }

      int? newSaPosId;
      if (page.schoolAPositionId != null) {
        final oldPos = await (database.select(database.position)
              ..where((t) => t.id.equals(page.schoolAPositionId!)))
            .getSingleOrNull();
        if (oldPos != null) {
          newSaPosId = await database.into(database.position).insert(
                PositionCompanion.insert(
                  xpos: drift.Value(oldPos.xpos),
                  ypos: drift.Value(oldPos.ypos),
                  size: drift.Value(oldPos.size),
                ),
              );
        }
      }

      int? newSbPosId;
      if (page.schoolBPositionId != null) {
        final oldPos = await (database.select(database.position)
              ..where((t) => t.id.equals(page.schoolBPositionId!)))
            .getSingleOrNull();
        if (oldPos != null) {
          newSbPosId = await database.into(database.position).insert(
                PositionCompanion.insert(
                  xpos: drift.Value(oldPos.xpos),
                  ypos: drift.Value(oldPos.ypos),
                  size: drift.Value(oldPos.size),
                ),
              );
        }
      }

      final newPage = await database.into(database.page).insertReturning(
            PageCompanion.insert(
              pageName: drift.Value(page.pageName),
              flowId: drift.Value(newFlow.id),
              pagePosition: drift.Value(page.pagePosition),
              pageTypeId: drift.Value(page.pageTypeId),
              sectionName: drift.Value(page.sectionName),
              bgmId: drift.Value(page.bgmId),
              hotkeyValue: drift.Value(page.hotkeyValue),
              sectionXpos: drift.Value(page.sectionXpos),
              sectionYpos: drift.Value(page.sectionYpos),
              sectionScale: drift.Value(page.sectionScale),
              sectionFontName: drift.Value(page.sectionFontName),
              timerFontName: drift.Value(page.timerFontName),
              useFrontpage: drift.Value(page.useFrontpage),
              isDefaultPage: drift.Value(page.isDefaultPage),
              showSchools: drift.Value(page.showSchools),
              sectionPositionId: drift.Value(newSecPosId),
              schoolAPositionId: drift.Value(newSaPosId),
              schoolBPositionId: drift.Value(newSbPosId),
              sectionFontColor: drift.Value(page.sectionFontColor),
              timerFontColor: drift.Value(page.timerFontColor),
            ),
          );

      // Copy timers
      final timers = await (database.select(database.timer)
            ..where((t) => t.pageId.equals(page.id)))
          .get();
      for (final timer in timers) {
        int? newTimerPosId;
        if (timer.positionId != null) {
          final oldPos = await (database.select(database.position)
                ..where((t) => t.id.equals(timer.positionId!)))
              .getSingleOrNull();
          if (oldPos != null) {
            newTimerPosId = await database.into(database.position).insert(
                  PositionCompanion.insert(
                    xpos: drift.Value(oldPos.xpos),
                    ypos: drift.Value(oldPos.ypos),
                    size: drift.Value(oldPos.size),
                  ),
                );
          }
        }

        await database.into(database.timer).insert(
              TimerCompanion.insert(
                pageId: drift.Value(newPage.id),
                timerTemplateId: drift.Value(timer.timerTemplateId),
                startTime: drift.Value(timer.startTime),
                timerType: drift.Value(timer.timerType),
                xpos: drift.Value(timer.xpos),
                ypos: drift.Value(timer.ypos),
                scale: drift.Value(timer.scale),
                positionId: drift.Value(newTimerPosId),
              ),
            );
      }

      // Copy images
      final images = await (database.select(database.images)
            ..where((t) => t.pageId.equals(page.id)))
          .get();
      for (final img in images) {
        int? newImgPosId;
        if (img.positionId != null) {
          final oldPos = await (database.select(database.position)
                ..where((t) => t.id.equals(img.positionId!)))
              .getSingleOrNull();
          if (oldPos != null) {
            newImgPosId = await database.into(database.position).insert(
                  PositionCompanion.insert(
                    xpos: drift.Value(oldPos.xpos),
                    ypos: drift.Value(oldPos.ypos),
                    size: drift.Value(oldPos.size),
                  ),
                );
          }
        }

        await database.into(database.images).insert(
              ImagesCompanion.insert(
                imageName: drift.Value(img.imageName),
                imageType: drift.Value(img.imageType),
                pageId: drift.Value(newPage.id),
                positionId: drift.Value(newImgPosId),
              ),
            );
      }
    }
    return newFlow;
  }
}
