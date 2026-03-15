import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../main.dart';

class TimerTemplateSettingsPage extends StatefulWidget {
  const TimerTemplateSettingsPage({super.key});

  @override
  State<TimerTemplateSettingsPage> createState() =>
      _TimerTemplateSettingsPageState();
}

class _TimerTemplateSettingsPageState extends State<TimerTemplateSettingsPage> {
  List<TimerTemplateData> _templates = [];
  List<DingAudioData> _dingAudios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final templates = await database.select(database.timerTemplate).get();
    final dingAudios = await database.select(database.dingAudio).get();
    if (mounted) {
      setState(() {
        _templates = templates;
        _dingAudios = dingAudios;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTemplatesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '计时器模板与铃声设计',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        FilledButton.icon(
          onPressed: () => _showTemplateDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加模板'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6B46C1),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesList() {
    if (_templates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.timer_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('暂无模板', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children:
          _templates.map((template) => _buildTemplateCard(template)).toList(),
    );
  }

  Widget _buildTemplateCard(TimerTemplateData template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          template.templateName ?? '未命名模板',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: FutureBuilder<DingAudioData?>(
          future: template.dingAudioId != null
              ? (database.select(database.dingAudio)
                    ..where((t) => t.id.equals(template.dingAudioId!)))
                  .getSingleOrNull()
              : Future.value(null),
          builder: (context, snapshot) {
            final audio = snapshot.data;
            return Text(
              '提示音: ${audio?.dingName ?? "无"}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF6B46C1), size: 20),
              onPressed: () => _showTemplateDialog(template: template),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(template),
            ),
          ],
        ),
        children: [
          _buildDingValuesList(template.id),
        ],
      ),
    );
  }

  Widget _buildDingValuesList(int templateId) {
    return FutureBuilder<List<DingValueData>>(
      future: (database.select(database.dingValue)
            ..where((t) => t.timerTemplateId.equals(templateId)))
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final values = snapshot.data!;
        if (values.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('暂无提示时间设置',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          );
        }
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map((v) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${v.dingTime} 响 ${v.dingAmount}下',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  void _showTemplateDialog({TimerTemplateData? template}) async {
    final nameController = TextEditingController(text: template?.templateName);
    int? selectedDingAudioId = template?.dingAudioId;
    List<_DingValueDraft> dingDrafts = [];

    if (template != null) {
      final existingDings = await (database.select(database.dingValue)
            ..where((t) => t.timerTemplateId.equals(template.id)))
          .get();
      dingDrafts = existingDings.map((d) {
        final parts = (d.dingTime ?? "0:0").split(':');
        return _DingValueDraft(
          min: parts[0],
          sec: parts.length > 1 ? parts[1] : '0',
          amount: d.dingAmount?.toString() ?? '1',
        );
      }).toList();
    } else {
      dingDrafts = [_DingValueDraft()];
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(template == null ? '添加计时器模板' : '编辑计时器模板'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('模板名称'),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: '例如: 正方立论计时',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('提示音 (Ding Audio)'),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedDingAudioId,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int>(
                                value: null, child: Text('无提示音')),
                            ..._dingAudios.map((d) => DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(d.dingName),
                                )),
                          ],
                          onChanged: (val) =>
                              setDialogState(() => selectedDingAudioId = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () => _uploadDingAudio((id) {
                          setDialogState(() => selectedDingAudioId = id);
                        }),
                        icon: const Icon(Icons.upload_rounded),
                        style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF6B46C1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('提示时间设置'),
                      TextButton.icon(
                        onPressed: () => setDialogState(
                            () => dingDrafts.add(_DingValueDraft())),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('添加'),
                      ),
                    ],
                  ),
                  ...dingDrafts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final draft = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildTimeField(draft.minController, '分')),
                          const SizedBox(width: 4),
                          Expanded(
                              child: _buildTimeField(draft.secController, '秒')),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: draft.amountController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                  labelText: '次数', isDense: true),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () =>
                                setDialogState(() => dingDrafts.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                if (template == null) {
                  final id = await database.into(database.timerTemplate).insert(
                        TimerTemplateCompanion.insert(
                          templateName: drift.Value(name),
                          dingAudioId: drift.Value(selectedDingAudioId),
                        ),
                      );
                  for (var d in dingDrafts) {
                    await database
                        .into(database.dingValue)
                        .insert(DingValueCompanion.insert(
                          dingTime: drift.Value(
                              '${d.minController.text}:${d.secController.text}'),
                          dingAmount: drift.Value(
                              int.tryParse(d.amountController.text) ?? 1),
                          timerTemplateId: drift.Value(id),
                        ));
                  }
                } else {
                  await (database.update(database.timerTemplate)
                        ..where((t) => t.id.equals(template.id)))
                      .write(TimerTemplateCompanion(
                    templateName: drift.Value(name),
                    dingAudioId: drift.Value(selectedDingAudioId),
                  ));
                  await (database.delete(database.dingValue)
                        ..where((t) => t.timerTemplateId.equals(template.id)))
                      .go();
                  for (var d in dingDrafts) {
                    await database
                        .into(database.dingValue)
                        .insert(DingValueCompanion.insert(
                          dingTime: drift.Value(
                              '${d.minController.text}:${d.secController.text}'),
                          dingAmount: drift.Value(
                              int.tryParse(d.amountController.text) ?? 1),
                          timerTemplateId: drift.Value(template.id),
                        ));
                  }
                }
                _loadData();
                if (context.mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1)),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      );

  Widget _buildTimeField(TextEditingController ctrl, String suffix) =>
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
            suffixText: suffix,
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50),
      );

  void _confirmDelete(TimerTemplateData template) async {
    final usages = await (database.select(database.timer)
          ..where((t) => t.timerTemplateId.equals(template.id)))
        .get();

    String usageInfo = '';
    if (usages.isNotEmpty) {
      final pageIds = usages.map((u) => u.pageId).whereType<int>().toSet();
      final pages = await (database.select(database.page)
            ..where((p) => p.id.isIn(pageIds)))
          .get();
      final flowIds = pages.map((p) => p.flowId).whereType<int>().toSet();
      final flows = await (database.select(database.flow)
            ..where((f) => f.id.isIn(flowIds)))
          .get();
      final eventIds = flows.map((f) => f.eventId).whereType<int>().toSet();
      final events = await (database.select(database.event)
            ..where((e) => e.id.isIn(eventIds)))
          .get();

      usageInfo = '\n\n此模板正在以下赛事中使用:\n' +
          events.map((e) => '• ${e.eventName}').join('\n') +
          '\n\n删除后，相关计时器的模板将变为空白。';
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模板 "${template.templateName}" 吗？$usageInfo'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              // 1. Nullify references in timers to avoid FK error
              await (database.update(database.timer)
                    ..where((t) => t.timerTemplateId.equals(template.id)))
                  .write(const TimerCompanion(
                      timerTemplateId: drift.Value(null)));

              // 2. Delete ding values
              await (database.delete(database.dingValue)
                    ..where((t) => t.timerTemplateId.equals(template.id)))
                  .go();

              // 3. Delete template
              await (database.delete(database.timerTemplate)
                    ..where((t) => t.id.equals(template.id)))
                  .go();

              _loadData();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDingAudio(Function(int) onUploaded) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final supportDir = await getApplicationSupportDirectory();
      final dingDir = Directory(p.join(supportDir.path, 'YiHuaTimer', 'ding'));
      if (!await dingDir.exists()) await dingDir.create(recursive: true);
      final destPath = p.join(dingDir.path, fileName);
      await file.copy(destPath);
      final id = await database
          .into(database.dingAudio)
          .insert(DingAudioCompanion.insert(dingName: fileName));
      final audios = await database.select(database.dingAudio).get();
      setState(() => _dingAudios = audios);
      onUploaded(id);
    }
  }
}

class _DingValueDraft {
  final TextEditingController minController;
  final TextEditingController secController;
  final TextEditingController amountController;

  _DingValueDraft({String min = '0', String sec = '0', String amount = '1'})
      : minController = TextEditingController(text: min),
        secController = TextEditingController(text: sec),
        amountController = TextEditingController(text: amount);
}
