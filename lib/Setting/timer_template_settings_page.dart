import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../main.dart';
import '../app_config.dart';

class TimerTemplateSettingsPage extends StatefulWidget {
  const TimerTemplateSettingsPage({super.key});

  @override
  State<TimerTemplateSettingsPage> createState() =>
      _TimerTemplateSettingsPageState();
}

class _TimerTemplateSettingsPageState extends State<TimerTemplateSettingsPage> {
  List<TimerTemplateData> _templates = [];
  List<TimerTemplateV2Data> _templatesV2 = [];
  List<DingAudioData> _dingAudios = [];
  bool _isLoading = true;

  StreamSubscription? _templatesSub;
  StreamSubscription? _templatesV2Sub;
  StreamSubscription? _dingAudiosSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  void dispose() {
    _templatesSub?.cancel();
    _templatesV2Sub?.cancel();
    _dingAudiosSub?.cancel();
    super.dispose();
  }

  void _setupStreams() {
    _templatesSub = database.select(database.timerTemplate).watch().listen((data) {
      if (mounted) setState(() => _templates = data);
    });
    _templatesV2Sub = database.select(database.timerTemplateV2).watch().listen((data) {
      if (mounted) setState(() => _templatesV2 = data);
    });
    _dingAudiosSub = database.select(database.dingAudio).watch().listen((data) {
      if (mounted) setState(() => _dingAudios = data);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final templates = await database.select(database.timerTemplate).get();
    final templatesV2 = await database.select(database.timerTemplateV2).get();
    final dingAudios = await database.select(database.dingAudio).get();
    if (mounted) {
      setState(() {
        _templates = templates;
        _templatesV2 = templatesV2;
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
            const SizedBox(height: 48),
            _buildHeaderV2(),
            const SizedBox(height: 24),
            _buildTemplatesV2List(),
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
            color: Colors.black.withValues(alpha: 0.02),
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
          title: Text(template == null ? '新建计时器模板' : '编辑计时器模板'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: '模板名称',
                    hint: '例如: 立论环节计时',
                  ),
                  const SizedBox(height: 16),

                  // Ding Audio Selection
                  const Text('提示音 (Ding Audio)',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedDingAudioId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                                value: null, child: Text('无提示音')),
                            ..._dingAudios.map((d) => DropdownMenuItem<int>(
                                  value: d.id,
                                  child: Text(d.dingName,
                                      overflow: TextOverflow.ellipsis),
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

                  // Ding Values Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('提示时间设置 (Ding Values)',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: () => setDialogState(
                                  () => dingDrafts.add(_DingValueDraft())),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('添加提示'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...dingDrafts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final draft = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                    child: _buildTimeField(
                                        draft.minController, '分')),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _buildTimeField(
                                        draft.secController, '秒')),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: draft.amountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: '次数',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setDialogState(
                                      () => dingDrafts.removeAt(index)),
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
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
              child: const Text('保存模板'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required String hint,
      bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12))),
      ],
    );
  }

  Widget _buildTimeField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            isDense: true,
            hintText: '0',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixText: label.substring(0, 1) == '分' ? 'm' : 's',
          ),
        ),
      ],
    );
  }

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
      final dingDir = Directory(p.join(AppConfig.dataPath(supportDir.path), 'ding'));
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

  Widget _buildHeaderV2() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '计时器模板 V2 (自定义单响铃声)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              '允许为每个提示时间设置不同的铃声',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => _showTemplateV2Dialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加 V2 模板'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesV2List() {
    if (_templatesV2.isEmpty) {
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
            Text('暂无 V2 模板', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: _templatesV2
          .map((template) => _buildTemplateV2Card(template))
          .toList(),
    );
  }

  Widget _buildTemplateV2Card(TimerTemplateV2Data template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
        subtitle: const Text('支持多铃声配置',
            style: TextStyle(fontSize: 12, color: Colors.green)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF059669), size: 20),
              onPressed: () => _showTemplateV2Dialog(template: template),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDeleteV2(template),
            ),
          ],
        ),
        children: [
          _buildDingValuesV2List(template.id),
        ],
      ),
    );
  }

  Widget _buildDingValuesV2List(int templateId) {
    return FutureBuilder<List<DingValueV2Data>>(
      future: (database.select(database.dingValueV2)
            ..where((t) => t.timerTemplateV2Id.equals(templateId)))
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
          child: Column(
            children: values.map((v) {
              return FutureBuilder<DingAudioData?>(
                future: v.dingAudioId != null
                    ? (database.select(database.dingAudio)
                          ..where((t) => t.id.equals(v.dingAudioId!)))
                        .getSingleOrNull()
                    : Future.value(null),
                builder: (context, audioSnapshot) {
                  final audio = audioSnapshot.data;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 16, color: Colors.indigo),
                        const SizedBox(width: 12),
                        Text(
                          '${v.dingTime} 响 ${v.dingAmount}下',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '铃声: ${audio?.dingName ?? "无"}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showTemplateV2Dialog({TimerTemplateV2Data? template}) async {
    final nameController = TextEditingController(text: template?.templateName);
    List<_DingValueV2Draft> dingDrafts = [];

    if (template != null) {
      final existingDings = await (database.select(database.dingValueV2)
            ..where((t) => t.timerTemplateV2Id.equals(template.id)))
          .get();
      dingDrafts = existingDings.map((d) {
        final parts = (d.dingTime ?? "0:0").split(':');
        return _DingValueV2Draft(
          min: parts[0],
          sec: parts.length > 1 ? parts[1] : '0',
          amount: d.dingAmount?.toString() ?? '1',
          dingAudioId: d.dingAudioId,
        );
      }).toList();
    } else {
      dingDrafts = [_DingValueV2Draft()];
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(template == null ? '新建计时器模板 V2' : '编辑计时器模板 V2'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: '模板名称',
                    hint: '例如: V2 高级计时模板',
                  ),
                  const SizedBox(height: 24),

                  // Ding Values Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('提示时间设置 (V2)',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: () => setDialogState(
                                  () => dingDrafts.add(_DingValueV2Draft())),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('添加提示'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...dingDrafts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final draft = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: _buildTimeField(
                                            draft.minController, '分')),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: _buildTimeField(
                                            draft.secController, '秒')),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        controller: draft.amountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelText: '次数',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => setDialogState(
                                          () => dingDrafts.removeAt(index)),
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Audio Selection for this ding
                                Row(
                                  children: [
                                    const Icon(Icons.music_note,
                                        size: 20, color: Colors.indigo),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: draft.dingAudioId,
                                        isExpanded: true,
                                        menuMaxHeight: 400,
                                        style: const TextStyle(fontSize: 14, color: Colors.black),
                                        decoration: InputDecoration(
                                          hintText: '为此时间选择铃声',
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                        ),
                                        items: [
                                          const DropdownMenuItem<int>(
                                              value: null, child: Text('无提示音')),
                                          ..._dingAudios.map((d) =>
                                              DropdownMenuItem<int>(
                                                value: d.id,
                                                child: Text(d.dingName,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              )),
                                        ],
                                        onChanged: (val) => setDialogState(
                                            () => draft.dingAudioId = val),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
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

                try {
                  if (template == null) {
                    final id = await database
                        .into(database.timerTemplateV2)
                        .insert(
                          TimerTemplateV2Companion.insert(
                            templateName: drift.Value(name),
                          ),
                        );
                    for (var d in dingDrafts) {
                      await database.into(database.dingValueV2).insert(
                            DingValueV2Companion.insert(
                              dingTime: drift.Value(
                                  '${d.minController.text}:${d.secController.text}'),
                              dingAmount: drift.Value(
                                  int.tryParse(d.amountController.text) ?? 1),
                              dingAudioId: drift.Value(d.dingAudioId),
                              timerTemplateV2Id: drift.Value(id),
                            ),
                          );
                    }
                  } else {
                    await (database.update(database.timerTemplateV2)
                          ..where((t) => t.id.equals(template.id)))
                        .write(TimerTemplateV2Companion(
                      templateName: drift.Value(name),
                    ));
                    await (database.delete(database.dingValueV2)
                          ..where(
                              (t) => t.timerTemplateV2Id.equals(template.id)))
                        .go();
                    for (var d in dingDrafts) {
                      await database.into(database.dingValueV2).insert(
                            DingValueV2Companion.insert(
                              dingTime: drift.Value(
                                  '${d.minController.text}:${d.secController.text}'),
                              dingAmount: drift.Value(
                                  int.tryParse(d.amountController.text) ?? 1),
                              dingAudioId: drift.Value(d.dingAudioId),
                              timerTemplateV2Id: drift.Value(template.id),
                            ),
                          );
                    }
                  }
                  _loadData();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('保存失败: $e')));
                  }
                }
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669)),
              child: const Text('保存 V2 模板'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteV2(TimerTemplateV2Data template) async {
    final usages = await (database.select(database.timer)
          ..where((t) => t.timerTemplateV2Id.equals(template.id)))
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

      usageInfo = '\n\n此 V2 模板正在以下赛事中使用:\n' +
          events.map((e) => '• ${e.eventName}').join('\n') +
          '\n\n删除后，相关计时器的模板将变为空白。';
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除 V2 模板'),
        content: Text('确定要删除 V2 模板 "${template.templateName}" 吗？$usageInfo'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await (database.update(database.timer)
                    ..where((t) => t.timerTemplateV2Id.equals(template.id)))
                  .write(const TimerCompanion(
                      timerTemplateV2Id: drift.Value(null)));

              await (database.delete(database.dingValueV2)
                    ..where((t) => t.timerTemplateV2Id.equals(template.id)))
                  .go();

              await (database.delete(database.timerTemplateV2)
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

class _DingValueV2Draft {
  final TextEditingController minController;
  final TextEditingController secController;
  final TextEditingController amountController;
  int? dingAudioId;

  _DingValueV2Draft(
      {String min = '0', String sec = '0', String amount = '1', this.dingAudioId})
      : minController = TextEditingController(text: min),
        secController = TextEditingController(text: sec),
        amountController = TextEditingController(text: amount);
}
