import 'dart:async' as async;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:drift/drift.dart' as drift;
import '../Setting/hotkey_binding_model.dart';
import '../database/app_database.dart';
import '../main.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerRunnerPage extends StatefulWidget {
  final EventData event;
  final FlowData flow;

  const TimerRunnerPage({super.key, required this.event, required this.flow});

  @override
  State<TimerRunnerPage> createState() => _TimerRunnerPageState();
}

class _TimerRunnerPageState extends State<TimerRunnerPage> {
  final PageController _pageController = PageController();
  List<PageData> _pages = [];
  List<PageData> _extraPages = [];
  PageData? _activeExtraPage;
  // Session-wide timer state: timerId -> currentSeconds
  final Map<int, int> _sessionTimerSeconds = {};
  bool _isLoading = true;
  String? _imagesDirPath;
  String? _fontFamily;
  String? _timerFontFamily;
  HotkeySettings? _hotkeySettings;
  final async.StreamController<String> _keyStreamController =
      async.StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    // Hide status bar and set to fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadSettings();
    _loadFlowData();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _keyStreamController.close();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('hotkey_settings');
    if (jsonString != null) {
      if (mounted) {
        setState(() {
          _hotkeySettings = HotkeySettings.fromJson(jsonDecode(jsonString));
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hotkeySettings = HotkeySettings.defaultSettings();
        });
      }
    }
  }

  Future<void> _loadFlowData() async {
    final supportDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(
        p.join(supportDir.path, 'YiHuaTimer', 'images', '${widget.event.id}'));
    _imagesDirPath = imagesDir.path;

    // Load flow-level fonts
    if (widget.flow.sectionFontName != null &&
        widget.flow.sectionFontName!.isNotEmpty) {
      await _loadFont(widget.flow.sectionFontName!, 'flow_section');
    } else if (widget.flow.fontName != null &&
        widget.flow.fontName!.isNotEmpty) {
      await _loadFont(widget.flow.fontName!, 'flow_section');
    }

    if (widget.flow.timerFontName != null &&
        widget.flow.timerFontName!.isNotEmpty) {
      await _loadFont(widget.flow.timerFontName!, 'flow_timer');
    } else if (widget.flow.fontName != null &&
        widget.flow.fontName!.isNotEmpty) {
      await _loadFont(widget.flow.fontName!, 'flow_timer');
    }

    final allPages = await (database.select(database.page)
          ..where((t) => t.flowId.equals(widget.flow.id))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.pagePosition)]))
        .get();

    if (mounted) {
      setState(() {
        _pages = allPages.where((p) => p.isDefaultPage == false).toList();
        _extraPages = allPages.where((p) => p.isDefaultPage == true).toList();
        _isLoading = false;
      });
    }
  }

  bool _isKnownHotkey(String key) {
    if (_hotkeySettings == null) return false;
    final k = key.toUpperCase();
    final h = _hotkeySettings!;
    return k == h.pageA1StartStop.key.toUpperCase() ||
        k == h.pageA1Reset.key.toUpperCase() ||
        k == h.pageA2LeftStartStop.key.toUpperCase() ||
        k == h.pageA2LeftReset.key.toUpperCase() ||
        k == h.pageA2RightStartStop.key.toUpperCase() ||
        k == h.pageA2RightReset.key.toUpperCase() ||
        k == h.pageA2Swap.key.toUpperCase();
  }

  Future<void> _loadFont(String fileName, String type) async {
    final supportDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(
        p.join(supportDir.path, 'YiHuaTimer', 'images', '${widget.event.id}'));
    final fontFile = File(p.join(imagesDir.path, fileName));
    if (await fontFile.exists()) {
      final family = 'Font_${type}_${widget.flow.id}';
      final fontLoader = FontLoader(family);
      fontLoader.addFont(
          Future.value(fontFile.readAsBytesSync().buffer.asByteData()));
      await fontLoader.load();
      if (type.contains('section')) _fontFamily = family;
      if (type.contains('timer')) _timerFontFamily = family;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_pages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            '该赛程没有页面',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent || _hotkeySettings == null) {
            return KeyEventResult.ignored;
          }

          final logicalKey = event.logicalKey;
          // Use keyLabel for alphanumeric keys, but check logicalKey for special keys
          String keyStr =
              logicalKey.keyLabel.toUpperCase().replaceAll('KEY ', '');

          if (logicalKey == LogicalKeyboardKey.space) keyStr = 'SPACE';
          if (logicalKey == LogicalKeyboardKey.escape) keyStr = 'ESCAPE';

          // Safeguard: Always ignore system/typing keys that shouldn't be hotkeys
          if (logicalKey == LogicalKeyboardKey.backspace ||
              logicalKey == LogicalKeyboardKey.enter ||
              logicalKey == LogicalKeyboardKey.tab) {
            return KeyEventResult.ignored;
          }

          // 1. Navigation & System Keys
          if (keyStr == _hotkeySettings!.previousPage.key.toUpperCase()) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            return KeyEventResult.handled;
          }
          if (keyStr == _hotkeySettings!.nextPage.key.toUpperCase()) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            return KeyEventResult.handled;
          }
          if (logicalKey == LogicalKeyboardKey.escape) {
            if (_activeExtraPage != null) {
              setState(() => _activeExtraPage = null);
            } else {
              Navigator.pop(context);
            }
            return KeyEventResult.handled;
          }

          // 2. Extra Page Switching
          for (var ep in _extraPages) {
            if (ep.hotkeyValue != null &&
                ep.hotkeyValue!.toUpperCase() == keyStr) {
              setState(() => _activeExtraPage = ep);
              return KeyEventResult.handled;
            }
          }

          // 3. Timer Hotkeys (send through stream)
          if (_isKnownHotkey(keyStr)) {
            _keyStreamController.add(keyStr);
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _TimerPageView(
                  pageData: _pages[index],
                  pageIndex: index,
                  pageController: _pageController,
                  keyStream: _keyStreamController.stream,
                  flow: widget.flow,
                  imagesDirPath: _imagesDirPath,
                  fontFamily: _fontFamily,
                  flowTimerFont: _timerFontFamily,
                  hotkeys: _hotkeySettings,
                  sessionTimerSeconds: _sessionTimerSeconds,
                  isActive: _activeExtraPage ==
                      null, // Main page only active if no extra page
                );
              },
            ),
            if (_activeExtraPage != null)
              Positioned.fill(
                child: _TimerPageView(
                  key: ValueKey('extra_${_activeExtraPage!.id}'),
                  pageData: _activeExtraPage!,
                  pageIndex: -999, // Special index for extra pages
                  pageController: _pageController,
                  keyStream: _keyStreamController.stream,
                  flow: widget.flow,
                  imagesDirPath: _imagesDirPath,
                  fontFamily: _fontFamily,
                  flowTimerFont: _timerFontFamily,
                  hotkeys: _hotkeySettings,
                  sessionTimerSeconds: _sessionTimerSeconds,
                  isActive: true, // Extra page is active if shown
                ),
              ),
            // Navigation controls overlay
            Positioned(
              bottom: 24,
              left: 24,
              child: FloatingActionButton(
                heroTag: 'back_btn',
                backgroundColor: Colors.white24,
                elevation: 0,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: Row(
                children: [
                  FloatingActionButton(
                    heroTag: 'prev_btn',
                    backgroundColor: Colors.white24,
                    elevation: 0,
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    heroTag: 'next_btn',
                    backgroundColor: Colors.white24,
                    elevation: 0,
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerPageView extends StatefulWidget {
  final PageData pageData;
  final int pageIndex;
  final PageController pageController;
  final async.Stream<String> keyStream;
  final FlowData flow;
  final String? imagesDirPath;
  final String? fontFamily;
  final String? flowTimerFont;
  final HotkeySettings? hotkeys;
  final Map<int, int> sessionTimerSeconds;
  final bool isActive;

  const _TimerPageView({
    super.key,
    required this.pageData,
    required this.pageIndex,
    required this.pageController,
    required this.keyStream,
    required this.flow,
    required this.sessionTimerSeconds,
    required this.isActive,
    this.imagesDirPath,
    this.fontFamily,
    this.flowTimerFont,
    this.hotkeys,
  });

  @override
  State<_TimerPageView> createState() => _TimerPageViewState();
}

class _TimerPageViewState extends State<_TimerPageView> {
  // Timer states
  int _secondsC = 0;
  bool _isRunning = false;
  async.Timer? _timerC;

  int _secL = 0;
  bool _isRunningL = false;
  async.Timer? _timerL;

  int _secR = 0;
  bool _isRunningR = false;
  async.Timer? _timerR;

  // Initial values for reset
  int _initSecC = 0;
  int _initSecL = 0;
  int _initSecR = 0;

  bool _isLoading = true;
  late async.StreamSubscription<String> _keySub;

  final Map<int, List<DingValueData>> _dingValues = {};
  final Map<int, String> _timerAudioFiles = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, int> _timerIdsByType = {};

  PositionData? _sectionPos;
  final Map<String, PositionData?> _timerPos = {};

  String? _pageSectionFont;
  String? _pageTimerFont;

  SchoolData? _schoolA;
  SchoolData? _schoolB;
  ImagesData? _logoA;
  ImagesData? _logoB;
  PositionData? _posA;
  PositionData? _posB;
  String? _schoolFontFamily;

  @override
  void initState() {
    super.initState();
    _loadTimers();
    _keySub = widget.keyStream.listen(_onKey);
  }

  void _onKey(String key) {
    if (!mounted || !widget.isActive) return;

    // Check if this page is active in the PageView
    if (widget.pageIndex != -999) {
      if (widget.pageController.hasClients) {
        final currentPage = widget.pageController.page?.round() ??
            widget.pageController.initialPage;
        if (currentPage != widget.pageIndex) return;
      } else {
        if (widget.pageIndex != 0) return;
      }
    }

    if (widget.hotkeys == null) return;

    if (widget.pageData.pageTypeId == 'A1') {
      if (key == widget.hotkeys!.pageA1StartStop.key.toUpperCase()) {
        _toggleC();
      } else if (key == widget.hotkeys!.pageA1Reset.key.toUpperCase()) {
        _timerC?.cancel();
        setState(() {
          _isRunning = false;
          _secondsC = _initSecC;
          final tid = _timerIdsByType['single'];
          if (tid != null) widget.sessionTimerSeconds[tid] = _secondsC;
        });
      }
    } else if (widget.pageData.pageTypeId == 'A2') {
      if (key == widget.hotkeys!.pageA2LeftStartStop.key.toUpperCase()) {
        _toggleL();
      } else if (key == widget.hotkeys!.pageA2LeftReset.key.toUpperCase()) {
        _timerL?.cancel();
        setState(() {
          _isRunningL = false;
          _secL = _initSecL;
          final tid = _timerIdsByType['doubleL'];
          if (tid != null) widget.sessionTimerSeconds[tid] = _secL;
        });
      } else if (key ==
          widget.hotkeys!.pageA2RightStartStop.key.toUpperCase()) {
        _toggleR();
      } else if (key == widget.hotkeys!.pageA2RightReset.key.toUpperCase()) {
        _timerR?.cancel();
        setState(() {
          _isRunningR = false;
          _secR = _initSecR;
          final tid = _timerIdsByType['doubleR'];
          if (tid != null) widget.sessionTimerSeconds[tid] = _secR;
        });
      } else if (key == widget.hotkeys!.pageA2Swap.key.toUpperCase()) {
        if (_isRunningL) {
          _toggleL();
          if (!_isRunningR) _toggleR();
        } else if (_isRunningR) {
          _toggleR();
          if (!_isRunningL) _toggleL();
        } else {
          // If neither is running, maybe start left by default
          _toggleL();
        }
      }
    }
  }

  @override
  void dispose() {
    _keySub.cancel();
    _timerC?.cancel();
    _timerL?.cancel();
    _timerR?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTimers() async {
    final timers = await (database.select(database.timer)
          ..where((t) => t.pageId.equals(widget.pageData.id)))
        .get();

    for (var t in timers) {
      final parts = (t.startTime ?? '0:0').split(':');
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final initSec = m * 60 + s;
      int currentSec = initSec;

      if (widget.sessionTimerSeconds.containsKey(t.id)) {
        currentSec = widget.sessionTimerSeconds[t.id]!;
      }

      if (t.timerType == 'single') {
        _initSecC = initSec;
        _secondsC = currentSec;
      } else if (t.timerType == 'doubleL') {
        _initSecL = initSec;
        _secL = currentSec;
      } else if (t.timerType == 'doubleR') {
        _initSecR = initSec;
        _secR = currentSec;
      }

      if (t.timerTemplateId != null) {
        final dings = await (database.select(database.dingValue)
              ..where((dv) => dv.timerTemplateId.equals(t.timerTemplateId!)))
            .get();
        _dingValues[t.id] = dings;

        final template = await (database.select(database.timerTemplate)
              ..where((tt) => tt.id.equals(t.timerTemplateId!)))
            .getSingleOrNull();

        if (template?.dingAudioId != null) {
          final audio = await (database.select(database.dingAudio)
                ..where((da) => da.id.equals(template!.dingAudioId!)))
              .getSingleOrNull();

          if (audio != null) {
            _timerAudioFiles[t.id] = audio.dingName;
          }
        }
      }

      // Load positions
      if (t.positionId != null) {
        final pos = await (database.select(database.position)
              ..where((p) => p.id.equals(t.positionId!)))
            .getSingleOrNull();
        _timerPos[t.timerType ?? ''] = pos;
      } else {
        // Fallback to legacy
        _timerPos[t.timerType ?? ''] = PositionData(
          id: -1,
          xpos: t.xpos,
          ypos: t.ypos,
          size: t.scale,
        );
      }
    }

    // Load section name position
    if (widget.pageData.sectionPositionId != null) {
      _sectionPos = await (database.select(database.position)
            ..where((p) => p.id.equals(widget.pageData.sectionPositionId!)))
          .getSingleOrNull();
    } else {
      _sectionPos = PositionData(
        id: -1,
        xpos: widget.pageData.sectionXpos,
        ypos: widget.pageData.sectionYpos,
        size: widget.pageData.sectionScale,
      );
    }

    // Load page-level fonts
    if (widget.pageData.sectionFontName != null &&
        widget.pageData.sectionFontName!.isNotEmpty) {
      await _loadPageFont(widget.pageData.sectionFontName!, 'page_section');
    }
    if (widget.pageData.timerFontName != null &&
        widget.pageData.timerFontName!.isNotEmpty) {
      await _loadPageFont(widget.pageData.timerFontName!, 'page_timer');
    }

    // Map timer types to IDs for easier lookup in _checkDings
    for (var t in timers) {
      _timerIdsByType[t.timerType ?? ''] = t.id;
    }

    await _loadSchoolInfo();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSchoolInfo() async {
    // 1. Fetch schools
    if (widget.flow.schoolAId != null) {
      _schoolA = await (database.select(database.school)
            ..where((t) => t.id.equals(widget.flow.schoolAId!)))
          .getSingleOrNull();

      if (_schoolA?.logoImageId != null) {
        _logoA = await (database.select(database.images)
              ..where((t) => t.id.equals(_schoolA!.logoImageId!)))
            .getSingleOrNull();
      }
    }
    if (widget.flow.schoolBId != null) {
      _schoolB = await (database.select(database.school)
            ..where((t) => t.id.equals(widget.flow.schoolBId!)))
          .getSingleOrNull();

      if (_schoolB?.logoImageId != null) {
        _logoB = await (database.select(database.images)
              ..where((t) => t.id.equals(_schoolB!.logoImageId!)))
            .getSingleOrNull();
      }
    }

    // 2. Fetch positions
    if (widget.pageData.schoolAPositionId != null) {
      _posA = await (database.select(database.position)
            ..where((t) => t.id.equals(widget.pageData.schoolAPositionId!)))
          .getSingleOrNull();
    }
    if (widget.pageData.schoolBPositionId != null) {
      _posB = await (database.select(database.position)
            ..where((t) => t.id.equals(widget.pageData.schoolBPositionId!)))
          .getSingleOrNull();
    }

    // 3. Load font family
    if (widget.flow.fontName?.isNotEmpty == true) {
      final fileName = widget.flow.fontName!;
      final supportDir = await getApplicationSupportDirectory();
      final imagesDir = Directory(p.join(
          supportDir.path, 'YiHuaTimer', 'images', '${widget.flow.eventId}'));
      final fontFile = File(p.join(imagesDir.path, fileName));

      if (await fontFile.exists()) {
        final family = 'Font_School_${widget.flow.id}';
        final fontLoader = FontLoader(family);
        fontLoader.addFont(
            Future.value(fontFile.readAsBytesSync().buffer.asByteData()));
        await fontLoader.load();
        _schoolFontFamily = family;
      }
    }
  }

  Future<void> _loadPageFont(String fileName, String type) async {
    final supportDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(p.join(
        supportDir.path, 'YiHuaTimer', 'images', '${widget.flow.eventId}'));
    final fontFile = File(p.join(imagesDir.path, fileName));
    if (await fontFile.exists()) {
      final family = 'Font_${type}_${widget.pageData.id}';
      final fontLoader = FontLoader(family);
      fontLoader.addFont(
          Future.value(fontFile.readAsBytesSync().buffer.asByteData()));
      await fontLoader.load();
      if (mounted) {
        setState(() {
          if (type.contains('section')) _pageSectionFont = family;
          if (type.contains('timer')) _pageTimerFont = family;
        });
      }
    }
  }

  void _toggleC() {
    if (_isRunning) {
      _timerC?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_secondsC > 0) {
        setState(() => _isRunning = true);
        _timerC = async.Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsC > 0) {
            setState(() {
              _secondsC--;
              final tid = _timerIdsByType['single'];
              if (tid != null) widget.sessionTimerSeconds[tid] = _secondsC;
            });
            _checkDings('single', _secondsC);
          } else {
            timer.cancel();
            setState(() => _isRunning = false);
          }
        });
      }
    }
  }

  Future<void> _checkDings(String type, int currentSec) async {
    final timerId = _timerIdsByType[type];
    if (timerId == null) return;

    final dings = _dingValues[timerId] ?? [];
    for (var d in dings) {
      final parts = (d.dingTime ?? '0:0').split(':');
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final dingSec = m * 60 + s;

      if (dingSec == currentSec) {
        _playSound(timerId, d.dingAmount ?? 1);
      }
    }
  }

  Future<void> _playSound(int timerId, int amount) async {
    final fileName = _timerAudioFiles[timerId];
    if (fileName == null || fileName.isEmpty) return;

    final supportDir = await getApplicationSupportDirectory();
    final audioPath = p.join(supportDir.path, 'YiHuaTimer', 'ding', fileName);

    if (!await File(audioPath).exists()) return;

    // Play the first ding immediately (no delay).
    _spawnPlay(audioPath);

    // Schedule any additional dings at 200ms intervals, detached so the
    // timer loop is never blocked.
    for (int i = 1; i < amount; i++) {
      Future.delayed(
          Duration(milliseconds: 200 * i), () => _spawnPlay(audioPath));
    }
  }

  /// Creates a short-lived AudioPlayer, plays once, then disposes itself.
  void _spawnPlay(String audioPath) {
    final player = AudioPlayer();
    player.play(DeviceFileSource(audioPath));
    player.onPlayerComplete.listen((_) => player.dispose());
  }

  void _toggleL() {
    if (_isRunningL) {
      _timerL?.cancel();
      setState(() => _isRunningL = false);
    } else {
      if (_secL > 0) {
        setState(() => _isRunningL = true);
        _timerL = async.Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secL > 0) {
            setState(() {
              _secL--;
              final tid = _timerIdsByType['doubleL'];
              if (tid != null) widget.sessionTimerSeconds[tid] = _secL;
            });
            _checkDings('doubleL', _secL);
          } else {
            timer.cancel();
            setState(() => _isRunningL = false);
          }
        });
      }
    }
  }

  void _toggleR() {
    if (_isRunningR) {
      _timerR?.cancel();
      setState(() => _isRunningR = false);
    } else {
      if (_secR > 0) {
        setState(() => _isRunningR = true);
        _timerR = async.Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secR > 0) {
            setState(() {
              _secR--;
              final tid = _timerIdsByType['doubleR'];
              if (tid != null) widget.sessionTimerSeconds[tid] = _secR;
            });
            _checkDings('doubleR', _secR);
          } else {
            timer.cancel();
            setState(() => _isRunningR = false);
          }
        });
      }
    }
  }

  String _format(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    String? bgImagePath;
    if (widget.imagesDirPath != null) {
      final imageName = (widget.pageData.useFrontpage ?? false)
          ? widget.flow.frontpageName
          : widget.flow.backgroundName;
      if (imageName != null && imageName.isNotEmpty) {
        bgImagePath = p.join(widget.imagesDirPath!, imageName);
      }
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          if (bgImagePath != null && File(bgImagePath).existsSync())
            Image.file(File(bgImagePath), fit: BoxFit.cover)
          else
            const Center(
              child: Text(
                '未上传背景图',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),

          // Overlay for readability
          Container(color: Colors.black26),

          // Content
          if (widget.pageData.pageTypeId != 'C')
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 100, horizontal: 100),
              child: Stack(
                children: [
                  // Section Name
                  Align(
                    alignment: widget.pageData.pageTypeId == 'B'
                        ? Alignment.center
                        : Alignment.topCenter,
                    child: Transform.translate(
                      offset: Offset(
                          _sectionPos?.xpos ?? 0,
                          (_sectionPos?.ypos ?? 0) +
                              (widget.pageData.pageTypeId == 'B' ? 0 : 0)),
                      child: Transform.scale(
                        scale: _sectionPos?.size ?? 1.0,
                        child: Text(
                          widget.pageData.sectionName ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: _pageSectionFont ?? widget.fontFamily,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Timer A1
                  if (widget.pageData.pageTypeId == 'A1')
                    Align(
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: Offset(_timerPos['single']?.xpos ?? 0,
                            _timerPos['single']?.ypos ?? 0),
                        child: Transform.scale(
                          scale: _timerPos['single']?.size ?? 1.0,
                          child: _buildTimerWidget(
                            time: _secondsC,
                            isRunning: _isRunning,
                            onToggle: _toggleC,
                            onReset: () {
                              _timerC?.cancel();
                              setState(() {
                                _isRunning = false;
                                _secondsC = _initSecC;
                                final tid = _timerIdsByType['single'];
                                if (tid != null)
                                  widget.sessionTimerSeconds[tid] = _secondsC;
                              });
                            },
                            isA2: false,
                          ),
                        ),
                      ),
                    ),

                  // Timer A2 Left
                  if (widget.pageData.pageTypeId == 'A2')
                    Align(
                      alignment: const Alignment(-0.5, 0.0),
                      child: Transform.translate(
                        offset: Offset(_timerPos['doubleL']?.xpos ?? 0,
                            _timerPos['doubleL']?.ypos ?? 0),
                        child: Transform.scale(
                          scale: _timerPos['doubleL']?.size ?? 1.0,
                          child: _buildTimerWidget(
                            time: _secL,
                            isRunning: _isRunningL,
                            onToggle: _toggleL,
                            onReset: () {
                              _timerL?.cancel();
                              setState(() {
                                _isRunningL = false;
                                _secL = _initSecL;
                                final tid = _timerIdsByType['doubleL'];
                                if (tid != null)
                                  widget.sessionTimerSeconds[tid] = _secL;
                              });
                            },
                            isA2: true,
                          ),
                        ),
                      ),
                    ),

                  // Timer A2 Right
                  if (widget.pageData.pageTypeId == 'A2')
                    Align(
                      alignment: const Alignment(0.5, 0.0),
                      child: Transform.translate(
                        offset: Offset(_timerPos['doubleR']?.xpos ?? 0,
                            _timerPos['doubleR']?.ypos ?? 0),
                        child: Transform.scale(
                          scale: _timerPos['doubleR']?.size ?? 1.0,
                          child: _buildTimerWidget(
                            time: _secR,
                            isRunning: _isRunningR,
                            onToggle: _toggleR,
                            onReset: () {
                              _timerR?.cancel();
                              setState(() {
                                _isRunningR = false;
                                _secR = _initSecR;
                                final tid = _timerIdsByType['doubleR'];
                                if (tid != null)
                                  widget.sessionTimerSeconds[tid] = _secR;
                              });
                            },
                            isA2: true,
                            isRight: true,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // School Info (Always show on all pages, matches PageManagerPage layout)
          Stack(
            children: [
              if (_schoolA != null)
                _buildSchoolRender(
                  _schoolA!,
                  _logoA,
                  _posA,
                  isA: true,
                ),
              if (_schoolB != null)
                _buildSchoolRender(
                  _schoolB!,
                  _logoB,
                  _posB,
                  isA: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolRender(
      SchoolData school, ImagesData? logo, PositionData? pos,
      {required bool isA}) {
    final logoWidget = FutureBuilder<Directory>(
      future: getApplicationSupportDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || logo?.imageName == null) {
          return const Icon(Icons.school, size: 60, color: Colors.black54);
        }
        final path = p.join(snapshot.data!.path, 'YiHuaTimer', 'schools',
            widget.flow.eventId.toString(), logo!.imageName!);
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
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
    );

    final content = isA
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
          );

    return Align(
      alignment: isA ? Alignment.bottomLeft : Alignment.bottomRight,
      child: Transform.translate(
        offset: Offset(pos?.xpos ?? 0, pos?.ypos ?? 0),
        child: Transform.scale(
          scale: pos?.size ?? 1.0,
          child: content,
        ),
      ),
    );
  }

  Widget _buildTimerWidget({
    required int time,
    required bool isRunning,
    required VoidCallback onToggle,
    required VoidCallback onReset,
    required bool isA2,
    bool isRight = false,
  }) {
    final double timerFontSize = isA2 ? 140 : 200;
    final double controlSize = timerFontSize * 0.2;
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          iconSize: controlSize,
          onPressed: onToggle,
          icon:
              Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black12,
            foregroundColor: Colors.black,
          ),
        ),
        const SizedBox(width: 24),
        IconButton.filled(
          iconSize: controlSize,
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black12,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );

    final timerText = SizedBox(
      width: 1000,
      child: Text(
        _format(time),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontSize: isA2 ? 140 : 200,
          fontWeight: FontWeight.bold,
          fontFamily:
              _pageTimerFont ?? widget.flowTimerFont ?? widget.fontFamily,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        timerText,
        const SizedBox(height: 24),
        controls,
      ],
    );
  }
}
