import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async' as async;
import 'dart:ui' as ui;
import '../database/app_database.dart';
import '../main.dart';

class PageManagerPage extends StatefulWidget {
  final EventData event;
  final FlowData flow;
  final PageData page;

  const PageManagerPage({
    super.key,
    required this.event,
    required this.flow,
    required this.page,
  });

  @override
  State<PageManagerPage> createState() => _PageManagerPageState();
}

class _PageManagerPageState extends State<PageManagerPage> {
  final _pageNameController = TextEditingController();
  final _sectionNameController = TextEditingController();

  List<BgmData> _bgmList = [];
  List<TimerTemplateData> _templateList = [];
  List<DingAudioData> _dingAudioList = [];
  int? _selectedBgmId;
  String? _selectedPageType;

  // Single Timer (A1)
  int? _singleTemplateId;
  final _singleMinController = TextEditingController(text: '0');
  final _singleSecController = TextEditingController(text: '0');

  // Double Timer (A2)
  int? _leftTemplateId;
  final _leftMinController = TextEditingController(text: '0');
  final _leftSecController = TextEditingController(text: '0');
  int? _rightTemplateId;
  final _rightMinController = TextEditingController(text: '0');
  final _rightSecController = TextEditingController(text: '0');

  bool _isLoading = true;
  late PageData _currentPage;

  // Preview State
  int _previewSeconds = 0;
  int _previewSecLeft = 0;
  int _previewSecRight = 0;
  bool _isPreviewRunning = false;
  bool _isPreviewRunningLeft = false;
  bool _isPreviewRunningRight = false;
  async.Timer? _previewTimer;
  async.Timer? _previewTimerLeft;
  async.Timer? _previewTimerRight;
  String? _backgroundPath;
  String? _fontPath;
  String? _fontFamily;

  bool _useFrontpage = false;

  async.StreamSubscription? _flowSub;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.page;
    _pageNameController.text = _currentPage.pageName ?? '';
    _sectionNameController.text = _currentPage.sectionName ?? '';
    _selectedBgmId = _currentPage.bgmId;
    _selectedPageType = _currentPage.pageTypeId;
    _useFrontpage = _currentPage.useFrontpage ?? false;

    _loadData();
    _loadTimerData();

    // Watch flow for asset updates
    _flowSub = (database.select(database.flow)
          ..where((t) => t.id.equals(widget.flow.id)))
        .watchSingle()
        .listen((flow) {
      _loadAssetPaths(flow);
    });

    // Listeners to update preview
    _sectionNameController.addListener(() => setState(() {}));
    _singleMinController.addListener(_updatePreviewSeconds);
    _singleSecController.addListener(_updatePreviewSeconds);
    _leftMinController.addListener(_updatePreviewSeconds);
    _leftSecController.addListener(_updatePreviewSeconds);
    _rightMinController.addListener(_updatePreviewSeconds);
    _rightSecController.addListener(_updatePreviewSeconds);
  }

  void _updatePreviewSeconds() {
    if (_selectedPageType == 'A1') {
      final min = int.tryParse(_singleMinController.text) ?? 0;
      final sec = int.tryParse(_singleSecController.text) ?? 0;
      setState(() {
        _previewSeconds = min * 60 + sec;
      });
    } else if (_selectedPageType == 'A2') {
      final lmin = int.tryParse(_leftMinController.text) ?? 0;
      final lsec = int.tryParse(_leftSecController.text) ?? 0;
      final rmin = int.tryParse(_rightMinController.text) ?? 0;
      final rsec = int.tryParse(_rightSecController.text) ?? 0;
      setState(() {
        _previewSecLeft = lmin * 60 + lsec;
        _previewSecRight = rmin * 60 + rsec;
      });
    }
  }

  Future<void> _loadAssetPaths(FlowData flow) async {
    final supportDir = await getApplicationSupportDirectory();
    final imagesPath = p.join(
        supportDir.path, 'YiHuaTimer', 'images', widget.event.id.toString());

    // Image logic: choose background or frontpage based on user choice
    String? selectedImageName;
    if (_useFrontpage && flow.frontpageName != null) {
      selectedImageName = flow.frontpageName;
    } else {
      selectedImageName = flow.backgroundName;
    }

    if (selectedImageName != null) {
      _backgroundPath = p.join(imagesPath, selectedImageName);
    } else {
      _backgroundPath = null;
    }

    if (flow.fontName != null) {
      _fontPath = p.join(imagesPath, flow.fontName!);
      _loadCustomFont(flow.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadCustomFont(int flowId) async {
    if (_fontPath == null) return;
    final file = File(_fontPath!);
    if (await file.exists()) {
      final fontData = await file.readAsBytes();
      final fontName = 'CustomFont_$flowId';
      final fontLoader = FontLoader(fontName);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
      if (mounted) {
        setState(() {
          _fontFamily = fontName;
        });
      }
    }
  }

  void _togglePreviewTimer() {
    if (_isPreviewRunning) {
      _previewTimer?.cancel();
    } else {
      _previewTimer = async.Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_previewSeconds > 0) {
          setState(() {
            _previewSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isPreviewRunning = false;
          });
        }
      });
    }
    setState(() {
      _isPreviewRunning = !_isPreviewRunning;
    });
  }

  void _togglePreviewTimerLeft() {
    if (_isPreviewRunningLeft) {
      _previewTimerLeft?.cancel();
    } else {
      _previewTimerLeft =
          async.Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_previewSecLeft > 0) {
          setState(() {
            _previewSecLeft--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isPreviewRunningLeft = false;
          });
        }
      });
    }
    setState(() {
      _isPreviewRunningLeft = !_isPreviewRunningLeft;
    });
  }

  void _togglePreviewTimerRight() {
    if (_isPreviewRunningRight) {
      _previewTimerRight?.cancel();
    } else {
      _previewTimerRight =
          async.Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_previewSecRight > 0) {
          setState(() {
            _previewSecRight--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isPreviewRunningRight = false;
          });
        }
      });
    }
    setState(() {
      _isPreviewRunningRight = !_isPreviewRunningRight;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    final bgms = await database.select(database.bgm).get();
    final templates = await database.select(database.timerTemplate).get();
    final dingAudios = await database.select(database.dingAudio).get();
    if (mounted) {
      setState(() {
        _bgmList = bgms;
        _templateList = templates;
        _dingAudioList = dingAudios;
      });
    }
  }

  Future<void> _loadTimerData() async {
    final timers = await (database.select(database.timer)
          ..where((t) => t.pageId.equals(_currentPage.id)))
        .get();

    if (mounted) {
      setState(() {
        for (final timer in timers) {
          if (timer.timerType == 'single') {
            _singleTemplateId = timer.timerTemplateId;
            final parts = (timer.startTime ?? '0:0').split(':');
            _singleMinController.text = parts[0];
            _singleSecController.text = parts.length > 1 ? parts[1] : '0';

            final m = int.tryParse(parts[0]) ?? 0;
            final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
            _previewSeconds = m * 60 + s;
          } else if (timer.timerType == 'doubleL') {
            _leftTemplateId = timer.timerTemplateId;
            final parts = (timer.startTime ?? '0:0').split(':');
            _leftMinController.text = parts[0];
            _leftSecController.text = parts.length > 1 ? parts[1] : '0';

            final m = int.tryParse(parts[0]) ?? 0;
            final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
            _previewSecLeft = m * 60 + s;
          } else if (timer.timerType == 'doubleR') {
            _rightTemplateId = timer.timerTemplateId;
            final parts = (timer.startTime ?? '0:1').split(':');
            _rightMinController.text = parts[0];
            _rightSecController.text = parts.length > 1 ? parts[1] : '0';

            final m = int.tryParse(parts[0]) ?? 0;
            final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
            _previewSecRight = m * 60 + s;
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _createTemplate() async {
    final nameController = TextEditingController();
    int? selectedDingAudioId;
    List<_DingValueDraft> dingDrafts = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建计时器模板'),
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
                            ..._dingAudioList.map((d) => DropdownMenuItem<int>(
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
                                    child: _buildTimeInput(
                                        draft.minController, '分')),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _buildTimeInput(
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

                try {
                  // 1. Save Template
                  final templateId =
                      await database.into(database.timerTemplate).insert(
                            TimerTemplateCompanion.insert(
                              templateName: drift.Value(name),
                              dingAudioId: drift.Value(selectedDingAudioId),
                            ),
                          );

                  // 2. Save Ding Values
                  for (final draft in dingDrafts) {
                    final time =
                        '${draft.minController.text}:${draft.secController.text}';
                    final amount =
                        int.tryParse(draft.amountController.text) ?? 1;
                    await database.into(database.dingValue).insert(
                          DingValueCompanion.insert(
                            dingTime: drift.Value(time),
                            dingAmount: drift.Value(amount),
                            timerTemplateId: drift.Value(templateId),
                          ),
                        );
                  }

                  await _loadData();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('保存失败: $e')));
                }
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

  Future<void> _uploadDingAudio(Function(int?) onUploadComplete) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      try {
        final supportDir = await getApplicationSupportDirectory();
        final dingDir =
            Directory(p.join(supportDir.path, 'YiHuaTimer', 'ding'));
        if (!await dingDir.exists()) await dingDir.create(recursive: true);

        final targetPath = p.join(dingDir.path, fileName);
        await file.copy(targetPath);

        final id = await database.into(database.dingAudio).insert(
              DingAudioCompanion.insert(dingName: fileName),
            );
        await _loadData();
        onUploadComplete(id);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('上传失败: $e')));
      }
    }
  }

  Future<void> _saveTimer(String type) async {
    int? templateId;
    String min = '0';
    String sec = '0';

    if (type == 'single') {
      templateId = _singleTemplateId;
      min = _singleMinController.text;
      sec = _singleSecController.text;
    } else if (type == 'doubleL') {
      templateId = _leftTemplateId;
      min = _leftMinController.text;
      sec = _leftSecController.text;
    } else if (type == 'doubleR') {
      templateId = _rightTemplateId;
      min = _rightMinController.text;
      sec = _rightSecController.text;
    }

    if (templateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择模板')),
      );
      return;
    }

    final startTime = '$min:$sec';

    try {
      // Check if exists
      final existing = await (database.select(database.timer)
            ..where((t) => t.pageId.equals(_currentPage.id))
            ..where((t) => t.timerType.equals(type)))
          .getSingleOrNull();

      if (existing != null) {
        await (database.update(database.timer)
              ..where((t) => t.id.equals(existing.id)))
            .write(TimerCompanion(
          timerTemplateId: drift.Value(templateId),
          startTime: drift.Value(startTime),
        ));
      } else {
        await database.into(database.timer).insert(TimerCompanion.insert(
              timerTemplateId: drift.Value(templateId),
              startTime: drift.Value(startTime),
              timerType: drift.Value(type),
              pageId: drift.Value(_currentPage.id),
            ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('计时器已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _uploadBgm() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      try {
        final supportDir = await getApplicationSupportDirectory();
        final bgmDir = Directory(p.join(supportDir.path, 'YiHuaTimer', 'bgm'));
        if (!await bgmDir.exists()) await bgmDir.create(recursive: true);

        final targetPath = p.join(bgmDir.path, fileName);
        await file.copy(targetPath);

        final bgmId = await database
            .into(database.bgm)
            .insert(BgmCompanion.insert(bgmName: fileName));

        await _loadData();
        setState(() {
          _selectedBgmId = bgmId;
        });

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('BGM已上传: $fileName')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('上传失败: $e')));
        }
      }
    }
  }

  Future<void> _saveDetails() async {
    try {
      await (database.update(database.page)
            ..where((t) => t.id.equals(_currentPage.id)))
          .write(PageCompanion(
        pageName: drift.Value(_pageNameController.text.trim()),
        sectionName: drift.Value(_sectionNameController.text.trim()),
        bgmId: drift.Value(_selectedBgmId),
        pageTypeId: drift.Value(_selectedPageType),
        useFrontpage: drift.Value(_useFrontpage),
      ));
      final updated = await (database.select(database.page)
            ..where((t) => t.id.equals(_currentPage.id)))
          .getSingle();
      setState(() {
        _currentPage = updated;
      });
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('页面信息已保存')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
    }
  }

  @override
  void dispose() {
    _flowSub?.cancel();
    _previewTimer?.cancel();
    _pageNameController.dispose();
    _sectionNameController.dispose();
    _singleMinController.dispose();
    _singleSecController.dispose();
    _leftMinController.dispose();
    _leftSecController.dispose();
    _rightMinController.dispose();
    _rightSecController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('${_currentPage.pageName} - 属性配置'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('基本信息 (General Info)'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  _buildTextField(
                      controller: _pageNameController,
                      label: '页面名称 (Page Name)',
                      hint: '例如: 第一页'),
                  const SizedBox(height: 16),

                  // BGM Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('封面/背景图选择',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B5563))),
                      SwitchListTile(
                        title: const Text('使用封面图 (Global Frontpage)',
                            style: TextStyle(fontSize: 14)),
                        subtitle: const Text('默认使用背景图',
                            style: TextStyle(fontSize: 12)),
                        value: _useFrontpage,
                        onChanged: (val) {
                          setState(() {
                            _useFrontpage = val;
                          });
                          // Re-load paths with the current flow data
                          (database.select(database.flow)
                                ..where((t) => t.id.equals(widget.flow.id)))
                              .getSingle()
                              .then((f) => _loadAssetPaths(f));
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('背景音乐 (BGM)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4B5563))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedBgmId,
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
                                    value: null, child: Text('无音乐')),
                                ..._bgmList.map((bgm) => DropdownMenuItem<int>(
                                      value: bgm.id,
                                      child: Text(bgm.bgmName,
                                          overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedBgmId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _uploadBgm,
                            icon: const Icon(Icons.upload_rounded),
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF6B46C1)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Page Type selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('页面类型 (Page Type)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4B5563))),
                      const SizedBox(height: 8),
                      Row(
                        children: ['A1', 'A2', 'B', 'C'].map((type) {
                          final isSelected = _selectedPageType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (val) => setState(
                                  () => _selectedPageType = val ? type : null),
                              selectedColor:
                                  const Color(0xFF6B46C1).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF6B46C1),
                              labelStyle: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF6B46C1)
                                      : Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedPageType != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            {
                                  'A1': '一个计时器，一个人说话罢了就用这个',
                                  'A2': '两个计时器，for 对辩，自由辩，计器 介绍用',
                                  'B': '没有计时器，显示阶段标题在中间',
                                  'C': '没有计时器或阶段标题，只显示背景',
                                }[_selectedPageType] ??
                                '',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                  if (_selectedPageType == 'A1' ||
                      _selectedPageType == 'A2' ||
                      _selectedPageType == 'B') ...[
                    const SizedBox(height: 24),
                    _buildTextField(
                        controller: _sectionNameController,
                        label: '环节名称 (Section Name)',
                        hint: '例如: 开场介绍'),
                  ],

                  const SizedBox(height: 24),
                  if (_selectedPageType == 'A1') ...[
                    Row(
                      children: [
                        Expanded(
                            child: _buildTimerBox(
                                '单计时器 (Single Timer)', 'single')),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ] else if (_selectedPageType == 'A2') ...[
                    Row(
                      children: [
                        Expanded(
                            child: _buildTimerBox(
                                '左侧计时器 (Left Timer)', 'doubleL')),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildTimerBox(
                                '右侧计时器 (Right Timer)', 'doubleR')),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 32),
                  _buildSectionTitle('页面预览 (Preview)'),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenSize = MediaQuery.of(context).size;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRect(
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: screenSize.height *
                                  (constraints.maxWidth / screenSize.width),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Container(
                                  width: screenSize.width,
                                  height: screenSize.height,
                                  color: Colors.black,
                                  child: Stack(
                                    children: [
                                      // Background
                                      if (_backgroundPath != null &&
                                          File(_backgroundPath!).existsSync())
                                        Positioned.fill(
                                            child: Image.file(
                                                File(_backgroundPath!),
                                                fit: BoxFit.cover))
                                      else
                                        const Positioned.fill(
                                            child: Center(
                                                child: Text('未上传背景图',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 32)))),

                                      // Overlay
                                      Positioned.fill(
                                          child:
                                              Container(color: Colors.black26)),

                                      // Content
                                      if (_selectedPageType != 'C')
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 100, horizontal: 100),
                                          child: Stack(
                                            children: [
                                              // Section Name
                                              Align(
                                                alignment:
                                                    _selectedPageType == 'B'
                                                        ? Alignment.center
                                                        : Alignment.topCenter,
                                                child: Text(
                                                  _sectionNameController
                                                          .text.isEmpty
                                                      ? (_selectedPageType ==
                                                              'B'
                                                          ? '中间环节名称预览'
                                                          : '环节名称预览')
                                                      : _sectionNameController
                                                          .text,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: _fontFamily,
                                                    shadows: [
                                                      Shadow(
                                                          color: Colors.black
                                                              .withOpacity(0.5),
                                                          blurRadius: 15,
                                                          offset: const Offset(
                                                              0, 6))
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Timer A1
                                              if (_selectedPageType == 'A1')
                                                Align(
                                                  alignment: Alignment.center,
                                                  child:
                                                      _buildPreviewTimerWidget(
                                                    time: _previewSeconds,
                                                    isRunning:
                                                        _isPreviewRunning,
                                                    onToggle:
                                                        _togglePreviewTimer,
                                                    onReset: () {
                                                      _previewTimer?.cancel();
                                                      _updatePreviewSeconds();
                                                      setState(() {
                                                        _isPreviewRunning =
                                                            false;
                                                      });
                                                    },
                                                  ),
                                                ),

                                              // Timer A2
                                              if (_selectedPageType == 'A2')
                                                Align(
                                                  alignment: Alignment.center,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      _buildPreviewTimerWidget(
                                                        time: _previewSecLeft,
                                                        isRunning:
                                                            _isPreviewRunningLeft,
                                                        onToggle:
                                                            _togglePreviewTimerLeft,
                                                        onReset: () {
                                                          _previewTimerLeft
                                                              ?.cancel();
                                                          _updatePreviewSeconds();
                                                          setState(() {
                                                            _isPreviewRunningLeft =
                                                                false;
                                                          });
                                                        },
                                                      ),
                                                      _buildPreviewTimerWidget(
                                                        time: _previewSecRight,
                                                        isRunning:
                                                            _isPreviewRunningRight,
                                                        onToggle:
                                                            _togglePreviewTimerRight,
                                                        onReset: () {
                                                          _previewTimerRight
                                                              ?.cancel();
                                                          _updatePreviewSeconds();
                                                          setState(() {
                                                            _isPreviewRunningRight =
                                                                false;
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                          onPressed: _saveDetails,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('保存基本配置'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6B46C1),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTimerWidget({
    required int time,
    required bool isRunning,
    required VoidCallback onToggle,
    required VoidCallback onReset,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(time),
          style: TextStyle(
            color: Colors.white,
            fontSize: 120, // Adjusted for layout system
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
            shadows: [
              Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min, // Changed to min
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              iconSize: 44, // Adjusted
              onPressed: onToggle,
              icon: Icon(
                  isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              iconSize: 44, // Adjusted
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerBox(String title, String type) {
    int? currentTemplateId;
    TextEditingController minCtrl;
    TextEditingController secCtrl;

    if (type == 'single') {
      currentTemplateId = _singleTemplateId;
      minCtrl = _singleMinController;
      secCtrl = _singleSecController;
    } else if (type == 'doubleL') {
      currentTemplateId = _leftTemplateId;
      minCtrl = _leftMinController;
      secCtrl = _leftSecController;
    } else {
      currentTemplateId = _rightTemplateId;
      minCtrl = _rightMinController;
      secCtrl = _rightSecController;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 20),

          // Template Select
          const Text('计时器模板',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: currentTemplateId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: _templateList
                      .map((t) => DropdownMenuItem<int>(
                            value: t.id,
                            child: Text(t.templateName ?? '未命名模板',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      if (type == 'single')
                        _singleTemplateId = val;
                      else if (type == 'doubleL')
                        _leftTemplateId = val;
                      else
                        _rightTemplateId = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _createTemplate,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Start Time
          const Text('起始时间',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTimeInput(minCtrl, '分 (Min)'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInput(secCtrl, '秒 (Sec)'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _saveTimer(type),
              icon: const Icon(Icons.timer_outlined, size: 18),
              label: const Text('保存计时器'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6B46C1)),
                foregroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(TextEditingController controller, String label) {
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

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827)));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required String hint}) {
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
            decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6B46C1))))),
      ],
    );
  }
}

class _DingValueDraft {
  final TextEditingController minController = TextEditingController(text: '0');
  final TextEditingController secController = TextEditingController(text: '0');
  final TextEditingController amountController =
      TextEditingController(text: '1');
}
