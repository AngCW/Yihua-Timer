import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../main.dart';
import '../database/app_database.dart';
import 'edit_timer_flow_page.dart';

// ─── Event Draft (Memory Only) ──────────────────────────────────────────────
class _EventDraft {
  String name = '';
  String desc = '';
  DateTimeRange? dateRange;
  String teamNum = '';
  String remark = '';
  String? votingDataPath;
  String? bgmPath;
  String? bgImgPath;
  int? eventId;

  _EventDraft();

  void clear() {
    name = '';
    desc = '';
    dateRange = null;
    teamNum = '';
    remark = '';
    votingDataPath = null;
    bgmPath = null;
    bgImgPath = null;
    eventId = null;
  }
}

// ─── root widget ─────────────────────────────────────────────────────────────
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  int _currentStep = 0;
  final _draft = _EventDraft();

  void _goToStep2() => setState(() => _currentStep = 1);
  void _goToStep1() => setState(() => _currentStep = 0);

  @override
  Widget build(BuildContext context) {
    return _currentStep == 0
        ? _EventFormPage(draft: _draft, onNext: _goToStep2)
        : _EventConfigPage(draft: _draft, onBack: _goToStep1);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE 1 – Event basic info form
// ════════════════════════════════════════════════════════════════════════════
class _EventFormPage extends StatefulWidget {
  final _EventDraft draft;
  final VoidCallback onNext;

  const _EventFormPage({required this.draft, required this.onNext});

  @override
  State<_EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<_EventFormPage> {
  late final _nameCtrl = TextEditingController(text: widget.draft.name);
  late final _descCtrl = TextEditingController(text: widget.draft.desc);
  late final _teamCtrl = TextEditingController(text: widget.draft.teamNum);
  late final _remarkCtrl = TextEditingController(text: widget.draft.remark);
  late final _dateCtrl = TextEditingController(
    text: widget.draft.dateRange != null
        ? '${DateFormat('yyyy-MM-dd').format(widget.draft.dateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(widget.draft.dateRange!.end)}'
        : '',
  );

  @override
  void dispose() {
    _persist();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _teamCtrl.dispose();
    _remarkCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _persist() {
    widget.draft.name = _nameCtrl.text;
    widget.draft.desc = _descCtrl.text;
    widget.draft.teamNum = _teamCtrl.text;
    widget.draft.remark = _remarkCtrl.text;
  }

  bool _validate() {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('请输入赛事名称');
      return false;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('请输入赛制简介');
      return false;
    }
    if (_dateCtrl.text.trim().isEmpty) {
      _snack('请选择日期');
      return false;
    }
    return true;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _next() {
    _persist();
    if (_validate()) widget.onNext();
  }

  Future<void> _pickDateRange() async {
    DateTime? start = widget.draft.dateRange?.start;
    DateTime? end = widget.draft.dateRange?.end;

    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => Dialog(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('选择日期范围',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ]),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: _DatePickerTile(
                    label: '开始日期',
                    date: start,
                    onPick: (d) => setDS(() => start = d),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _DatePickerTile(
                    label: '结束日期',
                    date: end,
                    firstDate: start,
                    onPick: (d) => setDS(() => end = d),
                  )),
                ]),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (start != null && end != null) {
                        Navigator.pop(
                            ctx, DateTimeRange(start: start!, end: end!));
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1)),
                    child: const Text('确定'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      widget.draft.dateRange = result;
      _persist();
      setState(() {
        _dateCtrl.text =
            '${DateFormat('yyyy-MM-dd').format(result.start)} - ${DateFormat('yyyy-MM-dd').format(result.end)}';
      });
    }
  }

  Future<void> _pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: type == 'bgm'
          ? FileType.audio
          : (type == 'bgImg' ? FileType.image : FileType.any),
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (type == 'voting')
          widget.draft.votingDataPath = result.files.single.path;
        if (type == 'bgm') widget.draft.bgmPath = result.files.single.path;
        if (type == 'bgImg') widget.draft.bgImgPath = result.files.single.path;
      });
      _persist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(fontSize: 14, color: Colors.grey.shade700);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('自定义赛事',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('根据需求自定义赛事信息',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 30),
              Text('赛事名称', style: labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                onChanged: (_) => _persist(),
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '请输入赛事名称'),
              ),
              const SizedBox(height: 24),
              Text('赛制简介', style: labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                onChanged: (_) => _persist(),
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '简单描述本次赛事或赛制'),
              ),
              const SizedBox(height: 24),
              Text('赛事日期', style: labelStyle),
              const SizedBox(height: 6),
              SizedBox(
                  width: 280,
                  child: TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _pickDateRange,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请选择日期',
                        suffixIcon:
                            Icon(Icons.calendar_today_rounded, size: 18)),
                  )),
              const SizedBox(height: 24),
              Text('参赛队数量', style: labelStyle),
              const SizedBox(height: 6),
              SizedBox(
                  width: 160,
                  child: TextFormField(
                    controller: _teamCtrl,
                    onChanged: (_) => _persist(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: '例如: 2'),
                  )),
              const SizedBox(height: 24),
              _UploadTile(
                  label: '投票数据表',
                  path: widget.draft.votingDataPath,
                  onPick: () => _pickFile('voting')),
              const SizedBox(height: 16),
              _UploadTile(
                  label: '背景音乐',
                  path: widget.draft.bgmPath,
                  onPick: () => _pickFile('bgm')),
              const SizedBox(height: 16),
              _UploadTile(
                  label: '背景图',
                  path: widget.draft.bgImgPath,
                  onPick: () => _pickFile('bgImg')),
              const SizedBox(height: 24),
              Text('备注', style: labelStyle),
              const SizedBox(height: 6),
              TextField(
                controller: _remarkCtrl,
                onChanged: (_) => _persist(),
                maxLines: 2,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '补充说明、特殊赛制要求等'),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12)),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('下一步 (赛制配置)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onPick;
  const _UploadTile(
      {required this.label, required this.path, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: Icon(
              path == null
                  ? Icons.upload_file_rounded
                  : Icons.check_circle_rounded,
              size: 18,
              color: path == null ? null : Colors.green),
          label: Text(path == null
              ? '点击上传'
              : '已选择: ${path!.split(Platform.pathSeparator).last}'),
          style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPick;
  const _DatePickerTile(
      {required this.label,
      required this.date,
      required this.onPick,
      this.firstDate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? firstDate ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    date != null
                        ? DateFormat('yyyy-MM-dd').format(date!)
                        : '选择日期',
                    style: TextStyle(
                        color: date != null ? Colors.black : Colors.grey)),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PAGE 2 – Timer templates + flows, and save event
// ════════════════════════════════════════════════════════════════════════════
class _EventConfigPage extends StatefulWidget {
  final _EventDraft draft;
  final VoidCallback onBack;

  const _EventConfigPage({required this.draft, required this.onBack});

  @override
  State<_EventConfigPage> createState() => _EventConfigPageState();
}

class _EventConfigPageState extends State<_EventConfigPage> {
  EventData? _savedEvent;
  final List<FlowData> _flows = [];
  bool _saving = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.draft.eventId != null) {
      _savedEvent = await (database.select(database.event)
            ..where((t) => t.id.equals(widget.draft.eventId!)))
          .getSingleOrNull();
    }

    // Always attempt to save (create or update) when proceeding to this page
    await _saveEvent(silent: true);

    if (_savedEvent != null) {
      final flows = await (database.select(database.flow)
            ..where((t) => t.eventId.equals(_savedEvent!.id))
            ..orderBy([(t) => drift.OrderingTerm(expression: t.flowPosition)]))
          .get();
      if (mounted) {
        setState(() {
          _flows.clear();
          _flows.addAll(flows);
        });
      }
    }

    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _saveEvent({bool silent = false}) async {
    if (widget.draft.name.trim().isEmpty) {
      if (!silent) _snack('赛事名称不能为空，请返回填写');
      return;
    }
    if (mounted) setState(() => _saving = true);
    try {
      final d = widget.draft;
      if (_savedEvent == null) {
        _savedEvent = await database.into(database.event).insertReturning(
              EventCompanion.insert(
                eventName: d.name,
                eventDesc: drift.Value(d.desc),
                startDate: drift.Value(d.dateRange?.start),
                endDate: drift.Value(d.dateRange?.end),
                teamNum: drift.Value(int.tryParse(d.teamNum)),
                remark: drift.Value(d.remark),
              ),
            );
        if (!silent) _snack('赛事已保存 ✓');
      } else {
        await (database.update(database.event)
              ..where((t) => t.id.equals(_savedEvent!.id)))
            .write(EventCompanion(
          eventName: drift.Value(d.name),
          eventDesc: drift.Value(d.desc),
          startDate: drift.Value(d.dateRange?.start),
          endDate: drift.Value(d.dateRange?.end),
          teamNum: drift.Value(int.tryParse(d.teamNum)),
          remark: drift.Value(d.remark),
        ));
        if (!silent) _snack('赛事已更新 ✓');
      }
    } catch (e) {
      if (!silent) _snack('保存失败: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _showAddFlowDialog() async {
    if (_savedEvent == null) {
      _snack('请先点击"保存赛事"，再添加赛程');
      return;
    }
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加计时器流程'),
        content: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: '例如: 初赛第一场')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1)),
              child: const Text('添加')),
        ],
      ),
    );

    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final flowName = nameCtrl.text.trim();
      final existing = await (database.select(database.flow)
            ..where((t) => t.eventId.equals(_savedEvent!.id)))
          .get();
      final newFlow = await database.into(database.flow).insertReturning(
          FlowCompanion.insert(
              flowName: drift.Value(flowName),
              eventId: drift.Value(_savedEvent!.id),
              flowPosition: drift.Value(existing.length + 1)));
      await _createDefaultPages(newFlow.id);
      setState(() => _flows.add(newFlow));
      _snack('赛程 "$flowName" 已添加');
    }
  }

  Future<void> _createDefaultPages(int flowId) async {
    final templates = await database.select(database.timerTemplate).get();
    final tid = templates.isNotEmpty ? templates.first.id : null;

    Future<void> insPage(
      String n,
      String pt,
      int p, {
      bool uf = false,
      String? sn,
      bool wt = false,
      bool isDefault = true,
      String? hotkey,
    }) async {
      final pg = await database.into(database.page).insertReturning(
            PageCompanion.insert(
              pageName: drift.Value(n),
              flowId: drift.Value(flowId),
              pagePosition: drift.Value(p),
              pageTypeId: drift.Value(pt),
              useFrontpage: drift.Value(uf),
              sectionName: drift.Value(sn),
              isDefaultPage: drift.Value(isDefault),
              hotkeyValue: drift.Value(hotkey),
            ),
          );
      if (wt && tid != null) {
        await database.into(database.timer).insert(
              TimerCompanion.insert(
                pageId: drift.Value(pg.id),
                timerTemplateId: drift.Value(tid),
                timerType: const drift.Value('single'),
                startTime: const drift.Value('2:0'),
              ),
            );
      }
    }

    await insPage('主页', 'C', 1, uf: true, isDefault: false);
    await insPage('断线缓冲计时环节', 'A1', 2, sn: '断线缓冲计时环节', wt: true, hotkey: '1');
    await insPage('断线缓冲标题页面', 'B', 3, sn: '断线缓冲标题页面', hotkey: '2');
    await insPage('立场捍卫环节', 'A1', 4, sn: '立场捍卫环节', wt: true, hotkey: '3');
    await insPage('资料检证环节', 'A1', 5, sn: '资料检证环节', wt: true, hotkey: '4');
  }

  // ── Delete flow ───────────────────────────────────────────────────────────
  Future<void> _deleteFlow(FlowData flow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除赛程'),
        content: Text('确定删除赛程 "${flow.flowName}" 吗？相关页面也将被删除。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final pages = await (database.select(database.page)
            ..where((t) => t.flowId.equals(flow.id)))
          .get();
      for (final pg in pages) {
        await (database.delete(database.timer)
              ..where((t) => t.pageId.equals(pg.id)))
            .go();
        await (database.delete(database.images)
              ..where((t) => t.pageId.equals(pg.id)))
            .go();
      }
      await (database.delete(database.page)
            ..where((t) => t.flowId.equals(flow.id)))
          .go();
      await (database.delete(database.flow)..where((t) => t.id.equals(flow.id)))
          .go();
      setState(() => _flows.remove(flow));
    } catch (e) {
      _snack('删除失败: $e');
    }
  }

  Future<void> _applyTemplateToAll(int tid) async {
    if (_savedEvent == null) {
      _snack('请先保存赛事');
      return;
    }
    final flows = await (database.select(database.flow)
          ..where((t) => t.eventId.equals(_savedEvent!.id)))
        .get();
    for (final f in flows) {
      final pgs = await (database.select(database.page)
            ..where((p) => p.flowId.equals(f.id)))
          .get();
      final ids = pgs.map((p) => p.id).toList();
      if (ids.isNotEmpty)
        await (database.update(database.timer)
              ..where((t) => t.pageId.isIn(ids)))
            .write(TimerCompanion(timerTemplateId: drift.Value(tid)));
    }
    _snack('已应用到所有页面');
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B46C1))),
            FilledButton.icon(
                onPressed: _saving ? null : _saveEvent,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1)),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(_savedEvent == null ? '保存赛事' : '更新赛事')),
          ]),
          const SizedBox(height: 24),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('计时器模板',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _TemplateSelector(onApply: _applyTemplateToAll),
                      ]))),
          const SizedBox(height: 24),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('计时器流程',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        if (_savedEvent == null)
                          const Text('\n请先保存赛事以添加赛程',
                              style: TextStyle(color: Colors.amber)),
                        const SizedBox(height: 24),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          ..._flows.map((f) => _FlowCard(
                                flow: f,
                                onDelete: () => _deleteFlow(f),
                              )),
                          _AddFlowCard(onTap: _showAddFlowDialog),
                        ]),
                      ]))),
        ],
      ),
    );
  }
}

class _TemplateSelector extends StatefulWidget {
  final Future<void> Function(int) onApply;
  const _TemplateSelector({required this.onApply});
  @override
  State<_TemplateSelector> createState() => _TemplateSelectorState();
}

class _TemplateSelectorState extends State<_TemplateSelector> {
  List<TimerTemplateData> _templates = [];
  int? _sel;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await database.select(database.timerTemplate).get();
    if (mounted) setState(() => _templates = t);
  }

  @override
  Widget build(BuildContext context) {
    if (_templates.isEmpty) return const Text('暂无计时器模板');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _templates
              .map((t) => ChoiceChip(
                  label: Text(t.templateName ?? ''),
                  selected: _sel == t.id,
                  onSelected: (s) => setState(() => _sel = s ? t.id : null)))
              .toList()),
      if (_sel != null)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(
                onPressed: () => widget.onApply(_sel!),
                child: const Text('应用到所有页面'))),
    ]);
  }
}

class _FlowCard extends StatelessWidget {
  final FlowData flow;
  final VoidCallback onDelete;
  const _FlowCard({required this.flow, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6B46C1).withOpacity(0.8),
              const Color(0xFF6B46C1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              flow.flowName ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '5 个预设页面',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                  onPressed: () {
                    EditTimerFlowPage.show(context, flow.flowName ?? '');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: '编辑',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon:
                      const Icon(Icons.delete, size: 18, color: Colors.white70),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: '删除',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFlowCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFlowCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              Icon(Icons.add, color: Color(0xFF6B46C1), size: 24),
              SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
