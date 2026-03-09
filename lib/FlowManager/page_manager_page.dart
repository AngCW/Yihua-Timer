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
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

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
  final _hotkeyController = TextEditingController();

  List<BgmData> _bgmList = [];
  List<TimerTemplateData> _templateList = [];
  List<DingAudioData> _dingAudioList = [];
  int? _selectedBgmId;
  String? _selectedPageType;
  bool _showSchools = true;

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

  // Position TextEditingControllers
  final _sectionXCtrl = TextEditingController();
  final _sectionYCtrl = TextEditingController();
  final _sectionScaleCtrl = TextEditingController();
  final _t1XCtrl = TextEditingController();
  final _t1YCtrl = TextEditingController();
  final _t1ScaleCtrl = TextEditingController();
  final _tlXCtrl = TextEditingController();
  final _tlYCtrl = TextEditingController();
  final _tlScaleCtrl = TextEditingController();
  final _trXCtrl = TextEditingController();
  final _trYCtrl = TextEditingController();
  final _trScaleCtrl = TextEditingController();

  // School A/B Position TextEditingControllers
  final _saxCtrl = TextEditingController();
  final _sayCtrl = TextEditingController();
  final _saScaleCtrl = TextEditingController();
  final _sbxCtrl = TextEditingController();
  final _sbyCtrl = TextEditingController();
  final _sbScaleCtrl = TextEditingController();

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
  String? _sectionFontFamily;
  String? _timerFontFamily;
  String? _schoolFontFamily;

  // Manual values for preview tweaks
  double _sectionX = 0;
  double _sectionY = 0;
  double _sectionScale = 1.0;

  // Single/Double Timer states
  double _t1X = 0, _t1Y = 0, _t1Scale = 1.0;
  double _tlX = 0, _tlY = 0, _tlScale = 1.0;
  double _trX = 0, _trY = 0, _trScale = 1.0;

  // School A/B Position states
  double _saX = 0, _saY = 0, _saScale = 1.0;
  double _sbX = 0, _sbY = 0, _sbScale = 1.0;

  // School Info for preview
  SchoolData? _schoolA;
  SchoolData? _schoolB;
  ImagesData? _schoolALogo;
  ImagesData? _schoolBLogo;

  void _syncPositionControllers() {
    _sectionXCtrl.text = _sectionX.toStringAsFixed(0);
    _sectionYCtrl.text = _sectionY.toStringAsFixed(0);
    _sectionScaleCtrl.text = _sectionScale.toStringAsFixed(2);
    _t1XCtrl.text = _t1X.toStringAsFixed(0);
    _t1YCtrl.text = _t1Y.toStringAsFixed(0);
    _t1ScaleCtrl.text = _t1Scale.toStringAsFixed(2);
    _tlXCtrl.text = _tlX.toStringAsFixed(0);
    _tlYCtrl.text = _tlY.toStringAsFixed(0);
    _tlScaleCtrl.text = _tlScale.toStringAsFixed(2);
    _trXCtrl.text = _trX.toStringAsFixed(0);
    _trYCtrl.text = _trY.toStringAsFixed(0);
    _trScaleCtrl.text = _trScale.toStringAsFixed(2);
    _saxCtrl.text = _saX.toStringAsFixed(0);
    _sayCtrl.text = _saY.toStringAsFixed(0);
    _saScaleCtrl.text = _saScale.toStringAsFixed(2);
    _sbxCtrl.text = _sbX.toStringAsFixed(0);
    _sbyCtrl.text = _sbY.toStringAsFixed(0);
    _sbScaleCtrl.text = _sbScale.toStringAsFixed(2);
  }

  bool _useFrontpage = false;

  // Position Data
  PositionData? _sectionPos;
  PositionData? _t1Pos;
  PositionData? _tLPos;
  PositionData? _tRPos;
  PositionData? _saPos;
  PositionData? _sbPos;

  final AudioPlayer _audioPlayer = AudioPlayer();

  async.StreamSubscription? _flowSub;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.page;
    _pageNameController.text = _currentPage.pageName ?? '';
    _sectionNameController.text = _currentPage.sectionName ?? '';
    _hotkeyController.text = _currentPage.hotkeyValue ?? '';
    _selectedBgmId = _currentPage.bgmId;
    // Default page type to A1 if not yet set
    _selectedPageType = _currentPage.pageTypeId ?? 'A1';
    _showSchools = _currentPage.showSchools ?? true;
    _useFrontpage = _currentPage.useFrontpage ?? false;

    _loadData();
    _loadTimerData();

    // Watch flow for asset updates
    _flowSub = (database.select(database.flow)
          ..where((t) => t.id.equals(widget.flow.id)))
        .watchSingle()
        .listen((flow) {
      _loadAssetPaths(flow);
      _loadFlowSchools(flow);
    });

    // Listeners to update preview
    _sectionNameController.addListener(() => setState(() {}));
    _singleMinController.addListener(_updatePreviewSeconds);
    _singleSecController.addListener(_updatePreviewSeconds);
    _leftMinController.addListener(_updatePreviewSeconds);
    _leftSecController.addListener(_updatePreviewSeconds);
    _rightMinController.addListener(_updatePreviewSeconds);
    _rightSecController.addListener(_updatePreviewSeconds);

    _loadFlowSchools(widget.flow);
  }

  Future<void> _loadFlowSchools(FlowData flow) async {
    if (flow.schoolAId != null) {
      _schoolA = await (database.select(database.school)
            ..where((t) => t.id.equals(flow.schoolAId!)))
          .getSingleOrNull();
      if (_schoolA?.logoImageId != null) {
        _schoolALogo = await (database.select(database.images)
              ..where((t) => t.id.equals(_schoolA!.logoImageId!)))
            .getSingleOrNull();
      }
    } else {
      _schoolA = null;
      _schoolALogo = null;
    }

    if (flow.schoolBId != null) {
      _schoolB = await (database.select(database.school)
            ..where((t) => t.id.equals(flow.schoolBId!)))
          .getSingleOrNull();
      if (_schoolB?.logoImageId != null) {
        _schoolBLogo = await (database.select(database.images)
              ..where((t) => t.id.equals(_schoolB!.logoImageId!)))
            .getSingleOrNull();
      }
    } else {
      _schoolB = null;
      _schoolBLogo = null;
    }
    if (mounted) setState(() {});
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
    _schoolFontFamily = null;
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

    // Determine font for section
    String? sectionFont;
    if (_currentPage.sectionFontName?.isNotEmpty == true) {
      sectionFont = _currentPage.sectionFontName;
    } else if (flow.sectionFontName?.isNotEmpty == true) {
      sectionFont = flow.sectionFontName;
    } else if (flow.fontName?.isNotEmpty == true) {
      sectionFont = flow.fontName;
    }

    // Determine font for timer
    String? timerFont;
    if (_currentPage.timerFontName?.isNotEmpty == true) {
      timerFont = _currentPage.timerFontName;
    } else if (flow.timerFontName?.isNotEmpty == true) {
      timerFont = flow.timerFontName;
    } else if (flow.fontName?.isNotEmpty == true) {
      timerFont = flow.fontName;
    }

    if (sectionFont != null) {
      _sectionFontFamily = await _loadCustomFont(sectionFont);
    }
    if (timerFont != null) {
      _timerFontFamily = await _loadCustomFont(timerFont);
    }

    // Load font for school names from flow.fontName
    if (flow.fontName?.isNotEmpty == true) {
      _schoolFontFamily = await _loadCustomFont(flow.fontName!);
    }

    if (mounted) setState(() {});
  }

  Future<String?> _loadCustomFont(String fileName) async {
    final supportDir = await getApplicationSupportDirectory();
    final imagesPath = p.join(
        supportDir.path, 'YiHuaTimer', 'images', widget.event.id.toString());
    final file = File(p.join(imagesPath, fileName));

    if (await file.exists()) {
      try {
        final fontData = await file.readAsBytes();
        final familyID =
            'Font_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        final fontLoader = FontLoader(familyID);
        fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
        await fontLoader.load();
        return familyID;
      } catch (e) {
        debugPrint('Error loading font $fileName: $e');
      }
    }
    return null;
  }

  Future<void> _uploadSpecificFont(String target) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf', 'woff', 'woff2'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName =
          'font_${target}_${DateTime.now().millisecondsSinceEpoch}${p.extension(result.files.single.path!)}';

      try {
        final supportDir = await getApplicationSupportDirectory();
        final imagesDir = Directory(p.join(supportDir.path, 'YiHuaTimer',
            'images', widget.event.id.toString()));
        if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

        final targetPath = p.join(imagesDir.path, fileName);
        await file.copy(targetPath);

        // Update database (Flow or Page level? User requested specific fonts for section vs timer)
        // We'll update the Flow globals if they want, but here we can update Page level for granular control
        if (target == 'section') {
          await (database.update(database.page)
                ..where((t) => t.id.equals(_currentPage.id)))
              .write(PageCompanion(sectionFontName: drift.Value(fileName)));
        } else {
          await (database.update(database.page)
                ..where((t) => t.id.equals(_currentPage.id)))
              .write(PageCompanion(timerFontName: drift.Value(fileName)));
        }

        final updated = await (database.select(database.page)
              ..where((t) => t.id.equals(_currentPage.id)))
            .getSingle();
        setState(() => _currentPage = updated);
        _loadAssetPaths(widget.flow);

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('字体上传成功')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('字体上传失败: $e')));
        }
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
          _checkPreviewDings(_singleTemplateId, _previewSeconds);
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

  Future<void> _checkPreviewDings(int? templateId, int currentSeconds) async {
    if (templateId == null) return;

    final dings = await (database.select(database.dingValue)
          ..where((t) => t.timerTemplateId.equals(templateId)))
        .get();

    final template = await (database.select(database.timerTemplate)
          ..where((t) => t.id.equals(templateId)))
        .getSingleOrNull();

    if (template?.dingAudioId != null) {
      final audio = await (database.select(database.dingAudio)
            ..where((t) => t.id.equals(template!.dingAudioId!)))
          .getSingleOrNull();

      if (audio != null) {
        for (var d in dings) {
          final parts = (d.dingTime ?? '0:0').split(':');
          final m = int.tryParse(parts[0]) ?? 0;
          final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
          final dingSec = m * 60 + s;

          if (dingSec == currentSeconds) {
            _playPreviewSound(audio.dingName, d.dingAmount ?? 1);
          }
        }
      }
    }
  }

  Future<void> _playPreviewSound(String fileName, int amount) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final audioPath = p.join(supportDir.path, 'YiHuaTimer', 'ding', fileName);

      if (!await File(audioPath).exists()) return;

      // Play the first ding immediately.
      _spawnPreviewPlay(audioPath);

      // Schedule any additional dings at 200ms intervals, detached.
      for (int i = 1; i < amount; i++) {
        Future.delayed(Duration(milliseconds: 200 * i),
            () => _spawnPreviewPlay(audioPath));
      }
    } catch (e) {
      debugPrint('Error playing preview sound: $e');
    }
  }

  void _spawnPreviewPlay(String audioPath) {
    final player = AudioPlayer();
    player.play(DeviceFileSource(audioPath));
    player.onPlayerComplete.listen((_) => player.dispose());
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
          _checkPreviewDings(_leftTemplateId, _previewSecLeft);
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
          _checkPreviewDings(_rightTemplateId, _previewSecRight);
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
    // 0. Initial hard defaults
    _sectionX = 0;
    _sectionY = 0;
    _sectionScale = 1.0;
    _t1X = 0;
    _t1Y = 0;
    _t1Scale = 1.0;
    _tlX = 0;
    _tlY = 0;
    _tlScale = 1.0;
    _trX = 0;
    _trY = 0;
    _trScale = 1.0;
    _saX = 0;
    _saY = 0;
    _saScale = 1.0;
    _sbX = 0;
    _sbY = 0;
    _sbScale = 1.0;

    // 1. Load Defaults from Flow Config
    Map<String, dynamic>? flowConfig;
    try {
      if (widget.flow.positionConfig != null) {
        flowConfig = jsonDecode(widget.flow.positionConfig!);
      }
    } catch (_) {}

    if (flowConfig != null) {
      // Look for per-type config first
      final typeConfig = flowConfig[_selectedPageType];
      if (typeConfig != null && typeConfig is Map<String, dynamic>) {
        if (typeConfig.containsKey('section')) {
          final m = typeConfig['section'];
          _sectionX = m['x']?.toDouble() ?? _sectionX;
          _sectionY = m['y']?.toDouble() ?? _sectionY;
          _sectionScale = m['s']?.toDouble() ?? _sectionScale;
        }
        if (typeConfig.containsKey('timer_single')) {
          final m = typeConfig['timer_single'];
          _t1X = m['x']?.toDouble() ?? _t1X;
          _t1Y = m['y']?.toDouble() ?? _t1Y;
          _t1Scale = m['s']?.toDouble() ?? _t1Scale;
        }
        if (typeConfig.containsKey('timer_doubleL')) {
          final m = typeConfig['timer_doubleL'];
          _tlX = m['x']?.toDouble() ?? _tlX;
          _tlY = m['y']?.toDouble() ?? _tlY;
          _tlScale = m['s']?.toDouble() ?? _tlScale;
        }
        if (typeConfig.containsKey('timer_doubleR')) {
          final m = typeConfig['timer_doubleR'];
          _trX = m['x']?.toDouble() ?? _trX;
          _trY = m['y']?.toDouble() ?? _trY;
          _trScale = m['s']?.toDouble() ?? _trScale;
        }
        if (typeConfig.containsKey('schoolA')) {
          final m = typeConfig['schoolA'];
          _saX = m['x']?.toDouble() ?? _saX;
          _saY = m['y']?.toDouble() ?? _saY;
          _saScale = m['s']?.toDouble() ?? _saScale;
        }
        if (typeConfig.containsKey('schoolB')) {
          final m = typeConfig['schoolB'];
          _sbX = m['x']?.toDouble() ?? _sbX;
          _sbY = m['y']?.toDouble() ?? _sbY;
          _sbScale = m['s']?.toDouble() ?? _sbScale;
        }
      } else {
        // Fallback to old flat format for backward compatibility
        if (flowConfig.containsKey('section')) {
          final m = flowConfig['section'];
          _sectionX = m['x']?.toDouble() ?? _sectionX;
          _sectionY = m['y']?.toDouble() ?? _sectionY;
          _sectionScale = m['s']?.toDouble() ?? _sectionScale;
        }
        if (flowConfig.containsKey('timer_single')) {
          final m = flowConfig['timer_single'];
          _t1X = m['x']?.toDouble() ?? _t1X;
          _t1Y = m['y']?.toDouble() ?? _t1Y;
          _t1Scale = m['s']?.toDouble() ?? _t1Scale;
        }
        if (flowConfig.containsKey('timer_doubleL')) {
          final m = flowConfig['timer_doubleL'];
          _tlX = m['x']?.toDouble() ?? _tlX;
          _tlY = m['y']?.toDouble() ?? _tlY;
          _tlScale = m['s']?.toDouble() ?? _tlScale;
        }
        if (flowConfig.containsKey('timer_doubleR')) {
          final m = flowConfig['timer_doubleR'];
          _trX = m['x']?.toDouble() ?? _trX;
          _trY = m['y']?.toDouble() ?? _trY;
          _trScale = m['s']?.toDouble() ?? _trScale;
        }
        if (flowConfig.containsKey('schoolA')) {
          final m = flowConfig['schoolA'];
          _saX = m['x']?.toDouble() ?? _saX;
          _saY = m['y']?.toDouble() ?? _saY;
          _saScale = m['s']?.toDouble() ?? _saScale;
        }
        if (flowConfig.containsKey('schoolB')) {
          final m = flowConfig['schoolB'];
          _sbX = m['x']?.toDouble() ?? _sbX;
          _sbY = m['y']?.toDouble() ?? _sbY;
          _sbScale = m['s']?.toDouble() ?? _sbScale;
        }
      }
    }

    // 2. Load specifics from Page (Override defaults)
    _sectionX = _currentPage.sectionXpos ?? _sectionX;
    _sectionY = _currentPage.sectionYpos ?? _sectionY;
    _sectionScale = _currentPage.sectionScale ?? _sectionScale;

    if (_currentPage.sectionPositionId != null) {
      _sectionPos = await (database.select(database.position)
            ..where((t) => t.id.equals(_currentPage.sectionPositionId!)))
          .getSingleOrNull();
      if (_sectionPos != null) {
        _sectionX = _sectionPos!.xpos ?? _sectionX;
        _sectionY = _sectionPos!.ypos ?? _sectionY;
        _sectionScale = _sectionPos!.size ?? _sectionScale;
      }
    }

    final timers = await (database.select(database.timer)
          ..where((t) => t.pageId.equals(_currentPage.id)))
        .get();

    // Load School A Position
    PositionData? saPos;
    if (_currentPage.schoolAPositionId != null) {
      saPos = await (database.select(database.position)
            ..where((t) => t.id.equals(_currentPage.schoolAPositionId!)))
          .getSingleOrNull();
    }

    // Load School B Position
    PositionData? sbPos;
    if (_currentPage.schoolBPositionId != null) {
      sbPos = await (database.select(database.position)
            ..where((t) => t.id.equals(_currentPage.schoolBPositionId!)))
          .getSingleOrNull();
    }

    if (mounted) {
      setState(() {
        for (final timer in timers) {
          if (timer.timerType == 'single') {
            _singleTemplateId = timer.timerTemplateId;
            final parts = (timer.startTime ?? '0:0').split(':');
            _singleMinController.text = parts[0];
            _singleSecController.text = parts.length > 1 ? parts[1] : '0';

            _previewSeconds = (int.tryParse(parts[0]) ?? 0) * 60 +
                (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);

            _t1Pos = null;
            if (timer.positionId != null) {
              _loadTimerPosition(timer.positionId!, 'single');
            } else {
              _t1X = timer.xpos ?? _t1X;
              _t1Y = timer.ypos ?? _t1Y;
              _t1Scale = timer.scale ?? _t1Scale;
            }
          } else if (timer.timerType == 'doubleL') {
            _leftTemplateId = timer.timerTemplateId;
            final parts = (timer.startTime ?? '0:0').split(':');
            _leftMinController.text = parts[0];
            _leftSecController.text = parts.length > 1 ? parts[1] : '0';

            _previewSecLeft = (int.tryParse(parts[0]) ?? 0) * 60 +
                (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);

            if (timer.positionId != null) {
              _loadTimerPosition(timer.positionId!, 'doubleL');
            } else {
              _tlX = timer.xpos ?? _tlX;
              _tlY = timer.ypos ?? _tlY;
              _tlScale = timer.scale ?? _tlScale;
            }
          } else if (timer.timerType == 'doubleR') {
            _rightTemplateId = timer.timerTemplateId;
            final parts = (timer.startTime ?? '0:0').split(':');
            _rightMinController.text = parts[0];
            _rightSecController.text = parts.length > 1 ? parts[1] : '0';

            _previewSecRight = (int.tryParse(parts[0]) ?? 0) * 60 +
                (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);

            if (timer.positionId != null) {
              _loadTimerPosition(timer.positionId!, 'doubleR');
            } else {
              _trX = timer.xpos ?? _trX;
              _trY = timer.ypos ?? _trY;
              _trScale = timer.scale ?? _trScale;
            }
          }
        }

        _saPos = saPos;
        if (_saPos != null) {
          _saX = _saPos!.xpos ?? _saX;
          _saY = _saPos!.ypos ?? _saY;
          _saScale = _saPos!.size ?? _saScale;
        }

        _sbPos = sbPos;
        if (_sbPos != null) {
          _sbX = _sbPos!.xpos ?? _sbX;
          _sbY = _sbPos!.ypos ?? _sbY;
          _sbScale = _sbPos!.size ?? _sbScale;
        }

        _isLoading = false;
      });
      _syncPositionControllers();
    }
  }

  Future<void> _loadTimerPosition(int id, String type) async {
    final pos = await (database.select(database.position)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (pos != null && mounted) {
      setState(() {
        if (type == 'single') {
          _t1Pos = pos;
          _t1X = pos.xpos ?? 0;
          _t1Y = pos.ypos ?? 0;
          _t1Scale = pos.size ?? 1.0;
        } else if (type == 'doubleL') {
          _tLPos = pos;
          _tlX = pos.xpos ?? 0;
          _tlY = pos.ypos ?? 0;
          _tlScale = pos.size ?? 1.0;
        } else if (type == 'doubleR') {
          _tRPos = pos;
          _trX = pos.xpos ?? 0;
          _trY = pos.ypos ?? 0;
          _trScale = pos.size ?? 1.0;
        }
      });
      _syncPositionControllers();
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
                          initialValue: selectedDingAudioId,
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('保存失败: $e')));
                  }
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
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('上传失败: $e')));
        }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择模板')));
      return;
    }

    final startTime = '$min:$sec';
    double x = 0, y = 0, s = 1.0;
    PositionData? currentPos;

    if (type == 'single') {
      x = _t1X;
      y = _t1Y;
      s = _t1Scale;
      currentPos = _t1Pos;
    } else if (type == 'doubleL') {
      x = _tlX;
      y = _tlY;
      s = _tlScale;
      currentPos = _tLPos;
    } else if (type == 'doubleR') {
      x = _trX;
      y = _trY;
      s = _trScale;
      currentPos = _tRPos;
    }

    try {
      int? positionId;
      if (currentPos != null) {
        await (database.update(database.position)
              ..where((t) => t.id.equals(currentPos!.id)))
            .write(PositionCompanion(
          xpos: drift.Value(x),
          ypos: drift.Value(y),
          size: drift.Value(s),
        ));
        positionId = currentPos.id;
      } else {
        positionId = await database.into(database.position).insert(
              PositionCompanion.insert(
                xpos: drift.Value(x),
                ypos: drift.Value(y),
                size: drift.Value(s),
              ),
            );
        // Update local state with the new position object
        final newPos = await (database.select(database.position)
              ..where((t) => t.id.equals(positionId!)))
            .getSingle();
        if (type == 'single') _t1Pos = newPos;
        if (type == 'doubleL') _tLPos = newPos;
        if (type == 'doubleR') _tRPos = newPos;
      }

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
          xpos: drift.Value(x),
          ypos: drift.Value(y),
          scale: drift.Value(s),
          positionId: drift.Value(positionId),
        ));
      } else {
        await database.into(database.timer).insert(TimerCompanion.insert(
              timerTemplateId: drift.Value(templateId),
              startTime: drift.Value(startTime),
              timerType: drift.Value(type),
              pageId: drift.Value(_currentPage.id),
              xpos: drift.Value(x),
              ypos: drift.Value(y),
              scale: drift.Value(s),
              positionId: drift.Value(positionId),
            ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('计时器已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
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
      int? sectionPosId;
      if (_sectionPos != null) {
        await (database.update(database.position)
              ..where((t) => t.id.equals(_sectionPos!.id)))
            .write(PositionCompanion(
          xpos: drift.Value(_sectionX),
          ypos: drift.Value(_sectionY),
          size: drift.Value(_sectionScale),
        ));
        sectionPosId = _sectionPos!.id;
      } else {
        sectionPosId = await database.into(database.position).insert(
              PositionCompanion.insert(
                xpos: drift.Value(_sectionX),
                ypos: drift.Value(_sectionY),
                size: drift.Value(_sectionScale),
              ),
            );
        // Update local state
        _sectionPos = await (database.select(database.position)
              ..where((t) => t.id.equals(sectionPosId!)))
            .getSingle();
      }

      // Handle School A position save
      int? saPosId;
      if (_saPos != null) {
        await (database.update(database.position)
              ..where((t) => t.id.equals(_saPos!.id)))
            .write(PositionCompanion(
          xpos: drift.Value(_saX),
          ypos: drift.Value(_saY),
          size: drift.Value(_saScale),
        ));
        saPosId = _saPos!.id;
      } else {
        saPosId = await database.into(database.position).insert(
              PositionCompanion.insert(
                xpos: drift.Value(_saX),
                ypos: drift.Value(_saY),
                size: drift.Value(_saScale),
              ),
            );
        _saPos = await (database.select(database.position)
              ..where((t) => t.id.equals(saPosId!)))
            .getSingle();
      }

      // Handle School B position save
      int? sbPosId;
      if (_sbPos != null) {
        await (database.update(database.position)
              ..where((t) => t.id.equals(_sbPos!.id)))
            .write(PositionCompanion(
          xpos: drift.Value(_sbX),
          ypos: drift.Value(_sbY),
          size: drift.Value(_sbScale),
        ));
        sbPosId = _sbPos!.id;
      } else {
        sbPosId = await database.into(database.position).insert(
              PositionCompanion.insert(
                xpos: drift.Value(_sbX),
                ypos: drift.Value(_sbY),
                size: drift.Value(_sbScale),
              ),
            );
        _sbPos = await (database.select(database.position)
              ..where((t) => t.id.equals(sbPosId!)))
            .getSingle();
      }

      await (database.update(database.page)
            ..where((t) => t.id.equals(_currentPage.id)))
          .write(PageCompanion(
        pageName: drift.Value(_pageNameController.text.trim()),
        sectionName: drift.Value(_sectionNameController.text.trim()),
        bgmId: drift.Value(_selectedBgmId),
        pageTypeId: drift.Value(_selectedPageType),
        useFrontpage: drift.Value(_useFrontpage),
        sectionXpos: drift.Value(_sectionX),
        sectionYpos: drift.Value(_sectionY),
        sectionScale: drift.Value(_sectionScale),
        sectionPositionId: drift.Value(sectionPosId),
        hotkeyValue: drift.Value(_hotkeyController.text.trim().isEmpty
            ? null
            : _hotkeyController.text.trim()),
        schoolAPositionId: drift.Value(saPosId),
        schoolBPositionId: drift.Value(sbPosId),
        showSchools: drift.Value(_showSchools),
      ));

      final updated = await (database.select(database.page)
            ..where((t) => t.id.equals(_currentPage.id)))
          .getSingle();
      setState(() {
        _currentPage = updated;
      });

      if (_selectedPageType == 'A1') {
        await _saveTimer('single');
      } else if (_selectedPageType == 'A2') {
        await _saveTimer('doubleL');
        await _saveTimer('doubleR');
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('页面基本配置及计时器已保存')));
        _askApplyPositionToAllPages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  @override
  void dispose() {
    _flowSub?.cancel();
    _previewTimer?.cancel();
    _previewTimerLeft?.cancel();
    _previewTimerRight?.cancel();
    _audioPlayer.dispose();
    _pageNameController.dispose();
    _sectionNameController.dispose();
    _hotkeyController.dispose();
    _singleMinController.dispose();
    _singleSecController.dispose();
    _leftMinController.dispose();
    _leftSecController.dispose();
    _rightMinController.dispose();
    _rightSecController.dispose();
    _sectionXCtrl.dispose();
    _sectionYCtrl.dispose();
    _sectionScaleCtrl.dispose();
    _t1XCtrl.dispose();
    _t1YCtrl.dispose();
    _t1ScaleCtrl.dispose();
    _tlXCtrl.dispose();
    _tlYCtrl.dispose();
    _tlScaleCtrl.dispose();
    _trXCtrl.dispose();
    _trYCtrl.dispose();
    _trScaleCtrl.dispose();
    _saxCtrl.dispose();
    _sayCtrl.dispose();
    _saScaleCtrl.dispose();
    _sbxCtrl.dispose();
    _sbyCtrl.dispose();
    _sbScaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _askApplyPositionToAllPages() async {
    if (!mounted) return;
    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('应用位置到全部页面'),
        content: const Text(
            '是否将当前页面中 环节名称、计时器、学校信息 的位置和大小配置，应用到同一赛程中的所有页面？\n\n（已有位置数据的页面将被覆盖）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('否，仅保存此页面'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('是，应用到全部'),
          ),
        ],
      ),
    );
    if (apply != true || !mounted) return;

    try {
      final pages = await (database.select(database.page)
            ..where((t) => t.flowId.equals(widget.flow.id))
            ..where((t) => t.pageTypeId.equals(_selectedPageType!))
            ..where((t) => t.id.isNotValue(_currentPage.id)))
          .get();

      await database.transaction(() async {
        for (final pg in pages) {
          // Upsert section position
          int? secPosId = pg.sectionPositionId;
          if (secPosId != null) {
            await (database.update(database.position)
                  ..where((t) => t.id.equals(secPosId!)))
                .write(PositionCompanion(
              xpos: drift.Value(_sectionX),
              ypos: drift.Value(_sectionY),
              size: drift.Value(_sectionScale),
            ));
          } else {
            secPosId = await database.into(database.position).insert(
                  PositionCompanion.insert(
                    xpos: drift.Value(_sectionX),
                    ypos: drift.Value(_sectionY),
                    size: drift.Value(_sectionScale),
                  ),
                );
          }
          await (database.update(database.page)
                ..where((t) => t.id.equals(pg.id)))
              .write(PageCompanion(
            sectionXpos: drift.Value(_sectionX),
            sectionYpos: drift.Value(_sectionY),
            sectionScale: drift.Value(_sectionScale),
            sectionPositionId: drift.Value(secPosId),
          ));

          // Upsert timer positions for matching types
          final timers = await (database.select(database.timer)
                ..where((t) => t.pageId.equals(pg.id)))
              .get();
          for (final t in timers) {
            double tx = 0, ty = 0, ts = 1.0;
            if (t.timerType == 'single') {
              tx = _t1X;
              ty = _t1Y;
              ts = _t1Scale;
            } else if (t.timerType == 'doubleL') {
              tx = _tlX;
              ty = _tlY;
              ts = _tlScale;
            } else if (t.timerType == 'doubleR') {
              tx = _trX;
              ty = _trY;
              ts = _trScale;
            }

            int? posId = t.positionId;
            if (posId != null) {
              await (database.update(database.position)
                    ..where((p) => p.id.equals(posId!)))
                  .write(PositionCompanion(
                xpos: drift.Value(tx),
                ypos: drift.Value(ty),
                size: drift.Value(ts),
              ));
            } else {
              posId = await database.into(database.position).insert(
                    PositionCompanion.insert(
                      xpos: drift.Value(tx),
                      ypos: drift.Value(ty),
                      size: drift.Value(ts),
                    ),
                  );
            }
            await (database.update(database.timer)
                  ..where((p) => p.id.equals(t.id)))
                .write(TimerCompanion(
              xpos: drift.Value(tx),
              ypos: drift.Value(ty),
              scale: drift.Value(ts),
              positionId: drift.Value(posId),
            ));
          }

          // Apply School Positions
          int? saPosId = pg.schoolAPositionId;
          if (saPosId != null) {
            await (database.update(database.position)
                  ..where((t) => t.id.equals(saPosId!)))
                .write(PositionCompanion(
              xpos: drift.Value(_saX),
              ypos: drift.Value(_saY),
              size: drift.Value(_saScale),
            ));
          } else {
            saPosId = await database.into(database.position).insert(
                  PositionCompanion.insert(
                    xpos: drift.Value(_saX),
                    ypos: drift.Value(_saY),
                    size: drift.Value(_saScale),
                  ),
                );
          }

          int? sbPosId = pg.schoolBPositionId;
          if (sbPosId != null) {
            await (database.update(database.position)
                  ..where((t) => t.id.equals(sbPosId!)))
                .write(PositionCompanion(
              xpos: drift.Value(_sbX),
              ypos: drift.Value(_sbY),
              size: drift.Value(_sbScale),
            ));
          } else {
            sbPosId = await database.into(database.position).insert(
                  PositionCompanion.insert(
                    xpos: drift.Value(_sbX),
                    ypos: drift.Value(_sbY),
                    size: drift.Value(_sbScale),
                  ),
                );
          }

          await (database.update(database.page)
                ..where((t) => t.id.equals(pg.id)))
              .write(PageCompanion(
            schoolAPositionId: drift.Value(saPosId),
            schoolBPositionId: drift.Value(sbPosId),
          ));
        }

        // Update Flow defaults for persistence for NEW pages
        Map<String, dynamic> existingConfig = {};
        try {
          if (widget.flow.positionConfig != null) {
            existingConfig = jsonDecode(widget.flow.positionConfig!);
          }
        } catch (_) {}

        final newConfig = Map<String, dynamic>.from(existingConfig);

        // Use nested config per page type
        final typeConfig =
            Map<String, dynamic>.from(newConfig[_selectedPageType!] ?? {});
        typeConfig['section'] = {
          'x': _sectionX,
          'y': _sectionY,
          's': _sectionScale
        };
        typeConfig['timer_single'] = {'x': _t1X, 'y': _t1Y, 's': _t1Scale};
        typeConfig['timer_doubleL'] = {'x': _tlX, 'y': _tlY, 's': _tlScale};
        typeConfig['timer_doubleR'] = {'x': _trX, 'y': _trY, 's': _trScale};
        typeConfig['schoolA'] = {'x': _saX, 'y': _saY, 's': _saScale};
        typeConfig['schoolB'] = {'x': _sbX, 'y': _sbY, 's': _sbScale};

        newConfig[_selectedPageType!] = typeConfig;

        await (database.update(database.flow)
              ..where((t) => t.id.equals(widget.flow.id)))
            .write(FlowCompanion(
          positionConfig: drift.Value(jsonEncode(newConfig)),
        ));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('位置已应用到同一类型的 ${pages.length} 个页面，并已保存为该类型的默认配置')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('批量应用失败: $e')));
      }
    }
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                      controller: _pageNameController,
                      label: '页面名称 (Page Name)',
                      hint: '例如: 第一页'),
                  const SizedBox(height: 16),

                  // Hotkey — only for default pages
                  if (_currentPage.isDefaultPage == true) ...[
                    _buildTextField(
                      controller: _hotkeyController,
                      label: '快捷键 (Hotkey)',
                      hint: '例如: 1',
                    ),
                    const SizedBox(height: 4),
                    Text('该快捷键用于计时器运行时直接跳转到此页面。',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                  ],

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
                              initialValue: _selectedBgmId,
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
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('显示学校名称和Logo (Show Schools)',
                            style: TextStyle(fontSize: 14)),
                        subtitle: const Text('关闭后将不在此页面显示学校信息',
                            style: TextStyle(fontSize: 12)),
                        value: _showSchools,
                        activeColor: const Color(0xFF6B46C1),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _showSchools = val;
                          });
                        },
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
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedPageType = type;
                                  });
                                  _loadTimerData();
                                }
                              },
                              selectedColor: const Color(0xFF6B46C1)
                                  .withValues(alpha: 0.2),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: _buildPositionControl(
                        label: '环节名称位置 (Section Name Position)',
                        x: _sectionX,
                        y: _sectionY,
                        scale: _sectionScale,
                        xCtrl: _sectionXCtrl,
                        yCtrl: _sectionYCtrl,
                        scaleCtrl: _sectionScaleCtrl,
                        onXChanged: (val) => setState(() => _sectionX = val),
                        onYChanged: (val) => setState(() => _sectionY = val),
                        onScaleChanged: (val) =>
                            setState(() => _sectionScale = val),
                      ),
                    ),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: _buildPositionControl(
                        label: '计时器位置 (Timer Position)',
                        x: _t1X,
                        y: _t1Y,
                        scale: _t1Scale,
                        xCtrl: _t1XCtrl,
                        yCtrl: _t1YCtrl,
                        scaleCtrl: _t1ScaleCtrl,
                        onXChanged: (val) => setState(() => _t1X = val),
                        onYChanged: (val) => setState(() => _t1Y = val),
                        onScaleChanged: (val) => setState(() => _t1Scale = val),
                      ),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPositionControl(
                            label: '左侧计时器位置',
                            x: _tlX,
                            y: _tlY,
                            scale: _tlScale,
                            xCtrl: _tlXCtrl,
                            yCtrl: _tlYCtrl,
                            scaleCtrl: _tlScaleCtrl,
                            onXChanged: (val) => setState(() => _tlX = val),
                            onYChanged: (val) => setState(() => _tlY = val),
                            onScaleChanged: (val) =>
                                setState(() => _tlScale = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPositionControl(
                            label: '右侧计时器位置',
                            x: _trX,
                            y: _trY,
                            scale: _trScale,
                            xCtrl: _trXCtrl,
                            yCtrl: _trYCtrl,
                            scaleCtrl: _trScaleCtrl,
                            onXChanged: (val) => setState(() => _trX = val),
                            onYChanged: (val) => setState(() => _trY = val),
                            onScaleChanged: (val) =>
                                setState(() => _trScale = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildFontPicker('环节字体', 'section')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildFontPicker('计时器字体', 'timer')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('学校 A 位置 (School A Config)'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200)),
                              child: _buildPositionControl(
                                label: '位置与大小 (Position & Scale)',
                                x: _saX,
                                y: _saY,
                                scale: _saScale,
                                xCtrl: _saxCtrl,
                                yCtrl: _sayCtrl,
                                scaleCtrl: _saScaleCtrl,
                                onXChanged: (val) => setState(() => _saX = val),
                                onYChanged: (val) => setState(() => _saY = val),
                                onScaleChanged: (val) =>
                                    setState(() => _saScale = val),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('学校 B 位置 (School B Config)'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200)),
                              child: _buildPositionControl(
                                label: '位置与大小 (Position & Scale)',
                                x: _sbX,
                                y: _sbY,
                                scale: _sbScale,
                                xCtrl: _sbxCtrl,
                                yCtrl: _sbyCtrl,
                                scaleCtrl: _sbScaleCtrl,
                                onXChanged: (val) => setState(() => _sbX = val),
                                onYChanged: (val) => setState(() => _sbY = val),
                                onScaleChanged: (val) =>
                                    setState(() => _sbScale = val),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

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
                                              _buildDraggableItem(
                                                alignment:
                                                    _selectedPageType == 'B'
                                                        ? Alignment.center
                                                        : Alignment.topCenter,
                                                x: _sectionX,
                                                y: _sectionY,
                                                scale: _sectionScale,
                                                onChanged: (dx, dy, s) {},
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
                                                    color: Colors.black,
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily:
                                                        _sectionFontFamily,
                                                    shadows: [
                                                      Shadow(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.5),
                                                          blurRadius: 15,
                                                          offset: const Offset(
                                                              0, 6))
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Timer A1
                                              if (_selectedPageType == 'A1')
                                                _buildDraggableItem(
                                                  alignment: Alignment.center,
                                                  x: _t1X,
                                                  y: _t1Y,
                                                  scale: _t1Scale,
                                                  onChanged: (dx, dy, s) {},
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
                                              if (_selectedPageType ==
                                                  'A2') ...[
                                                _buildDraggableItem(
                                                  alignment: const Alignment(
                                                      -0.5, 0.0),
                                                  x: _tlX,
                                                  y: _tlY,
                                                  scale: _tlScale,
                                                  onChanged: (dx, dy, s) {},
                                                  child:
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
                                                ),
                                                _buildDraggableItem(
                                                  alignment:
                                                      const Alignment(0.5, 0.0),
                                                  x: _trX,
                                                  y: _trY,
                                                  scale: _trScale,
                                                  onChanged: (dx, dy, s) {},
                                                  child:
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
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      // School Logos & Names
                                      if (_showSchools) ...[
                                        _buildDraggableItem(
                                          alignment: Alignment.bottomLeft,
                                          x: _saX,
                                          y: _saY,
                                          scale: _saScale,
                                          onChanged: (dx, dy, s) {},
                                          child: _buildSchoolPreview(
                                              _schoolA, _schoolALogo,
                                              isA: true),
                                        ),
                                        _buildDraggableItem(
                                          alignment: Alignment.bottomRight,
                                          x: _sbX,
                                          y: _sbY,
                                          scale: _sbScale,
                                          onChanged: (dx, dy, s) {},
                                          child: _buildSchoolPreview(
                                              _schoolB, _schoolBLogo,
                                              isA: false),
                                        ),
                                      ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 800,
          child: Text(
            _formatTime(time),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 120,
              fontWeight: FontWeight.bold,
              fontFamily: _timerFontFamily,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
              shadows: [
                Shadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min, // Changed to min
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              iconSize: 120 * 0.2,
              onPressed: onToggle,
              icon: Icon(
                  isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black12,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              iconSize: 120 * 0.2,
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black12,
                foregroundColor: Colors.black,
              ),
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
                  initialValue: currentTemplateId,
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
                      if (type == 'single') {
                        _singleTemplateId = val;
                      } else if (type == 'doubleL') {
                        _leftTemplateId = val;
                      } else {
                        _rightTemplateId = val;
                      }
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

  Widget _buildDraggableItem({
    Alignment alignment = Alignment.center,
    required double x,
    required double y,
    required double scale,
    required Function(double, double, double) onChanged,
    required Widget child,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(x, y),
        child: Transform.scale(
          scale: scale,
          child: child,
        ),
      ),
    );
  }

  Widget _buildFontPicker(String title, String target) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          IconButton(
            onPressed: () => _uploadSpecificFont(target),
            icon: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.font_download_rounded, size: 20),
                SizedBox(width: 4),
                Text('上传', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionControl({
    required String label,
    required double x,
    required double y,
    required double scale,
    required TextEditingController xCtrl,
    required TextEditingController yCtrl,
    required TextEditingController scaleCtrl,
    required ValueChanged<double> onXChanged,
    required ValueChanged<double> onYChanged,
    required ValueChanged<double> onScaleChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPositionInput(
                label: 'X POS',
                controller: xCtrl,
                onChanged: onXChanged,
                icon: Icons.swap_horiz_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPositionInput(
                label: 'Y POS',
                controller: yCtrl,
                onChanged: onYChanged,
                icon: Icons.swap_vert_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPositionInput(
                label: 'SIZE',
                controller: scaleCtrl,
                onChanged: onScaleChanged,
                icon: Icons.zoom_in_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPositionInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: Colors.grey.shade400),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    if (d != null) onChanged(d);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolPreview(SchoolData? school, ImagesData? logo,
      {required bool isA}) {
    if (school == null) return const SizedBox.shrink();

    final logoWidget = FutureBuilder<Directory>(
      future: getApplicationSupportDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || logo?.imageName == null) {
          return const Icon(Icons.school, size: 60, color: Colors.black54);
        }
        final path = p.join(snapshot.data!.path, 'YiHuaTimer', 'schools',
            widget.event.id.toString(), logo!.imageName!);
        if (!File(path).existsSync()) {
          return const Icon(Icons.school, size: 60, color: Colors.black54);
        }
        return Image.file(File(path),
            width: 100, height: 100, fit: BoxFit.contain);
      },
    );

    final nameWidget = Text(
      school.schoolName,
      style: TextStyle(
        color: Colors.black,
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFamily: _schoolFontFamily,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      child: isA
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                logoWidget,
                const SizedBox(width: 16),
                nameWidget,
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                nameWidget,
                const SizedBox(width: 16),
                logoWidget,
              ],
            ),
    );
  }
}

class _DingValueDraft {
  final TextEditingController minController = TextEditingController(text: '0');
  final TextEditingController secController = TextEditingController(text: '0');
  final TextEditingController amountController =
      TextEditingController(text: '1');
}
