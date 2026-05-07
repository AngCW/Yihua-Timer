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
import '../app_config.dart';

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
  final Set<int> _manuallyInteractedTimerIds = {};
  bool _isLoading = true;
  String? _imagesDirPath;
  String? _fontFamily;
  String? _timerFontFamily;
  HotkeySettings? _hotkeySettings;
  final async.StreamController<String> _keyStreamController =
      async.StreamController<String>.broadcast();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  int? _currentBgmId;
  int _currentPageIndex = 0;
  double _bgmVolume = 0.5;
  double _dingVolume = 0.7;
  String? _volumeMessage;
  async.Timer? _volumeMessageTimer;

  @override
  void initState() {
    super.initState();
    // Hide status bar and set to fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadSettings();
    _loadFlowData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showLanguageReminder();
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _keyStreamController.close();
    _bgmPlayer.dispose();
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

    if (mounted) {
      setState(() {
        _bgmVolume = prefs.getDouble('bgm_volume') ?? 0.5;
        _dingVolume = prefs.getDouble('ringtone_volume') ?? 0.7;
      });
      _bgmPlayer.setVolume(_bgmVolume);
    }
  }

  void _showVolumeIndicator(String message) {
    _volumeMessageTimer?.cancel();
    setState(() => _volumeMessage = message);
    _volumeMessageTimer = async.Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _volumeMessage = null);
    });
  }

  void _adjustVolume(bool isBgm, bool up) {
    setState(() {
      if (isBgm) {
        _bgmVolume = (_bgmVolume + (up ? 0.05 : -0.05)).clamp(0.0, 1.0);
        _bgmPlayer.setVolume(_bgmVolume);
        _showVolumeIndicator('BGM 音量: ${(_bgmVolume * 100).toInt()}%');
      } else {
        _dingVolume = (_dingVolume + (up ? 0.05 : -0.05)).clamp(0.0, 1.0);
        _showVolumeIndicator('提示音 音量: ${(_dingVolume * 100).toInt()}%');
      }
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble(isBgm ? 'bgm_volume' : 'ringtone_volume', isBgm ? _bgmVolume : _dingVolume);
    });
  }

  Future<void> _loadFlowData() async {
    final supportDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(
        p.join(AppConfig.dataPath(supportDir.path), 'images', '${widget.event.id}'));
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
        if (_pages.isNotEmpty) {
          _updateBgm(_pages[0]);
        }
      });
    }
  }

  Future<void> _updateBgm(PageData page) async {
    if (page.bgmId == _currentBgmId) return;

    _currentBgmId = page.bgmId;
    await _bgmPlayer.stop();

    if (page.bgmId != null) {
      final bgm = await (database.select(database.bgm)
            ..where((t) => t.id.equals(page.bgmId!)))
          .getSingleOrNull();

      if (bgm != null) {
        final supportDir = await getApplicationSupportDirectory();
        final bgmPath =
            p.join(AppConfig.dataPath(supportDir.path), 'bgm', bgm.bgmName);
        if (await File(bgmPath).exists()) {
          await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
          await _bgmPlayer.setSource(DeviceFileSource(bgmPath));
          await _bgmPlayer.setVolume(_bgmVolume);
          await _bgmPlayer.resume();
        }
      }
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
        p.join(AppConfig.dataPath(supportDir.path), 'images', '${widget.event.id}'));
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

          // Volume controls
          if (keyStr == _hotkeySettings!.bgmVolumeUp.key.toUpperCase()) {
            _adjustVolume(true, true);
            return KeyEventResult.handled;
          }
          if (keyStr == _hotkeySettings!.bgmVolumeDown.key.toUpperCase()) {
            _adjustVolume(true, false);
            return KeyEventResult.handled;
          }
          if (keyStr == _hotkeySettings!.dingVolumeUp.key.toUpperCase()) {
            _adjustVolume(false, true);
            return KeyEventResult.handled;
          }
          if (keyStr == _hotkeySettings!.dingVolumeDown.key.toUpperCase()) {
            _adjustVolume(false, false);
            return KeyEventResult.handled;
          }
          if (logicalKey == LogicalKeyboardKey.escape) {
            if (_activeExtraPage != null) {
              setState(() => _activeExtraPage = null);
              _updateBgm(_pages[_currentPageIndex]);
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
              _updateBgm(ep);
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
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                  if (_activeExtraPage == null) {
                    _updateBgm(_pages[index]);
                  }
                });
              },
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
                  isActive: _activeExtraPage == null && index == _currentPageIndex,
                  allPages: _pages,
                  dingVolume: _dingVolume,
                  manuallyInteractedTimerIds: _manuallyInteractedTimerIds,
                  onTimerInteracted: (tid) => _manuallyInteractedTimerIds.add(tid),
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
                   allPages: _pages,
                   dingVolume: _dingVolume,
                   manuallyInteractedTimerIds: _manuallyInteractedTimerIds,
                   onTimerInteracted: (tid) => _manuallyInteractedTimerIds.add(tid),
                ),
              ),
            if (_volumeMessage != null)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _volumeMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
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
  void _showLanguageReminder() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        // Auto-dismiss after 6 seconds
        async.Timer? timer;
        timer = async.Timer(const Duration(seconds: 6), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 400,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.keyboard_outlined, color: Colors.amber.shade400, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '快捷键提示 (Hotkey Tip)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '把电脑的语言换去English',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.amber.shade100,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '华文打pinyin的方格会影响快捷键',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        timer?.cancel();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade500,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '我知道了 (Got it)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  final List<PageData> allPages;
  final Map<int, int> sessionTimerSeconds;
  final bool isActive;
  final double dingVolume;
  final Set<int> manuallyInteractedTimerIds;
  final Function(int)? onTimerInteracted;

  const _TimerPageView({
    super.key,
    required this.pageData,
    required this.pageIndex,
    required this.pageController,
    required this.keyStream,
    required this.flow,
    required this.sessionTimerSeconds,
    required this.isActive,
    required this.allPages,
    required this.dingVolume,
    this.imagesDirPath,
    this.fontFamily,
    this.flowTimerFont,
    this.hotkeys,
    required this.manuallyInteractedTimerIds,
    this.onTimerInteracted,
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

  final Map<int, List<dynamic>> _dingValues = {};
  final Map<int, String> _timerAudioFiles = {};
  final Map<int, bool> _timerIsV2 = {};
  final Map<int, String> _dingV2AudioNames = {}; // For V2: map dingValueV2Id to audioName
  final List<AudioPlayer> _dingPool = List.generate(3, (_) => AudioPlayer());
  int _nextPoolIndex = 0;
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

  @override
  void didUpdateWidget(covariant _TimerPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When this page becomes the active page and it inherits, re-apply
    // inheritance so the timer values reflect the parent's latest state.
    if (widget.pageData.inheritTimerFromId != null &&
        !oldWidget.isActive &&
        widget.isActive) {
      _reapplyInheritance();
    }
  }

  /// Re-reads the parent timer values and updates local state without
  /// reloading the full timer configuration (positions, dings, etc.)
  Future<void> _reapplyInheritance() async {
    if (widget.pageData.inheritTimerFromId == null) return;

    final timers = await (database.select(database.timer)
          ..where((t) => t.pageId.equals(widget.pageData.id)))
        .get();

    for (var t in timers) {
      if (widget.manuallyInteractedTimerIds.contains(t.id)) continue;
      final parts = (t.startTime ?? '0:0').split(':');
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final initSec = m * 60 + s;

      final parentTimers = await (database.select(database.timer)
            ..where((pt) =>
                pt.pageId.equals(widget.pageData.inheritTimerFromId!))
            ..where((pt) => pt.timerType.equals(t.timerType!)))
          .get();

      if (parentTimers.isNotEmpty) {
        final parentVal = widget.sessionTimerSeconds[parentTimers.first.id];
        if (parentVal != null) {
          int newSec = parentVal;
          if (widget.pageData.inheritTimerRangeEnabled == true) {
            final minVal = widget.pageData.inheritTimerMin ?? 0;
            final maxVal = widget.pageData.inheritTimerMax ?? 0;
            if (maxVal > 0 && newSec > maxVal) {
              newSec = maxVal;
            }
            if (newSec < minVal) {
              newSec = minVal;
            }
          } else {
            newSec = parentVal > initSec ? initSec : parentVal;
          }
          widget.sessionTimerSeconds[t.id] = newSec;
          if (mounted) {
            setState(() {
              if (t.timerType == 'single') _secondsC = newSec;
              if (t.timerType == 'doubleL') _secL = newSec;
              if (t.timerType == 'doubleR') _secR = newSec;
            });
          }
        }
      }
    }
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
        final tid = _timerIdsByType['single'];
        if (tid != null) widget.onTimerInteracted?.call(tid);
      } else if (key == widget.hotkeys!.pageA1Reset.key.toUpperCase()) {
        _timerC?.cancel();
        setState(() {
          _isRunning = false;
          _secondsC = _initSecC;
          final tid = _timerIdsByType['single'];
          if (tid != null) {
            widget.sessionTimerSeconds[tid] = _secondsC;
            widget.onTimerInteracted?.call(tid);
          }
        });
      }
    } else if (widget.pageData.pageTypeId == 'A2') {
      if (key == widget.hotkeys!.pageA2LeftStartStop.key.toUpperCase()) {
        _toggleL();
        final tid = _timerIdsByType['doubleL'];
        if (tid != null) widget.onTimerInteracted?.call(tid);
      } else if (key == widget.hotkeys!.pageA2LeftReset.key.toUpperCase()) {
        _timerL?.cancel();
        setState(() {
          _isRunningL = false;
          _secL = _initSecL;
          final tid = _timerIdsByType['doubleL'];
          if (tid != null) {
            widget.sessionTimerSeconds[tid] = _secL;
            widget.onTimerInteracted?.call(tid);
          }
        });
      } else if (key ==
          widget.hotkeys!.pageA2RightStartStop.key.toUpperCase()) {
        _toggleR();
        final tid = _timerIdsByType['doubleR'];
        if (tid != null) widget.onTimerInteracted?.call(tid);
      } else if (key == widget.hotkeys!.pageA2RightReset.key.toUpperCase()) {
        _timerR?.cancel();
        setState(() {
          _isRunningR = false;
          _secR = _initSecR;
          final tid = _timerIdsByType['doubleR'];
          if (tid != null) {
            widget.sessionTimerSeconds[tid] = _secR;
            widget.onTimerInteracted?.call(tid);
          }
        });
      } else if (key == widget.hotkeys!.pageA2Swap.key.toUpperCase()) {
        if (_isRunningL) {
          _toggleL();
          if (!_isRunningR) _toggleR();
        } else if (_isRunningR) {
          _toggleR();
          if (!_isRunningL) _toggleL();
        } else {
          if (_secL == 0 && _secR > 0) {
            _toggleR();
          } else if (_secR == 0 && _secL > 0) {
            _toggleL();
          } else {
            _toggleL();
          }
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
    for (var p in _dingPool) {
      p.dispose();
    }
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

      // If this page inherits from another, always re-read the parent's
      // current value — even if we already have a cached entry for this timer.
      // This fixes stale inheritance when navigating back to this page
      // after the parent timer has been running.
      if (widget.pageData.inheritTimerFromId != null && !widget.manuallyInteractedTimerIds.contains(t.id)) {
        final parentTimers = await (database.select(database.timer)
              ..where(
                  (pt) => pt.pageId.equals(widget.pageData.inheritTimerFromId!))
              ..where((pt) => pt.timerType.equals(t.timerType!)))
            .get();
        if (parentTimers.isNotEmpty) {
          final parentVal = widget.sessionTimerSeconds[parentTimers.first.id];
          if (parentVal != null) {
            currentSec = parentVal;
            if (widget.pageData.inheritTimerRangeEnabled == true) {
              final minVal = widget.pageData.inheritTimerMin ?? 0;
              final maxVal = widget.pageData.inheritTimerMax ?? 0;
              if (maxVal > 0 && currentSec > maxVal) {
                currentSec = maxVal;
              }
              if (currentSec < minVal) {
                currentSec = minVal;
              }
            } else {
              currentSec = parentVal > initSec ? initSec : parentVal;
            }
            widget.sessionTimerSeconds[t.id] = currentSec;
          }
        }
      } else if (widget.sessionTimerSeconds.containsKey(t.id)) {
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
        _timerIsV2[t.id] = false;
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
      } else if (t.timerTemplateV2Id != null) {
        _timerIsV2[t.id] = true;
        final dings = await (database.select(database.dingValueV2)
              ..where((dv) => dv.timerTemplateV2Id.equals(t.timerTemplateV2Id!)))
            .get();
        _dingValues[t.id] = dings;

        for (var dv in dings) {
          if (dv.dingAudioId != null) {
            final audio = await (database.select(database.dingAudio)
                  ..where((da) => da.id.equals(dv.dingAudioId!)))
                .getSingleOrNull();
            if (audio != null) {
              _dingV2AudioNames[dv.id] = audio.dingName;
            }
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
          AppConfig.dataPath(supportDir.path), 'images', '${widget.flow.eventId}'));
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
        AppConfig.dataPath(supportDir.path), 'images', '${widget.flow.eventId}'));
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
        final tid = _timerIdsByType['single'];
        if (tid != null) widget.onTimerInteracted?.call(tid);
        setState(() => _isRunning = true);
        _timerC = async.Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secondsC > 0) {
            setState(() {
              _secondsC--;
              final tid = _timerIdsByType['single'];
              if (tid != null) {
                widget.sessionTimerSeconds[tid] = _secondsC;
              }
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

    final isV2 = _timerIsV2[timerId] ?? false;
    final dings = _dingValues[timerId] ?? [];
    for (var d in dings) {
      final String timeStr = isV2 ? (d as DingValueV2Data).dingTime ?? '0:0' : (d as DingValueData).dingTime ?? '0:0';
      final parts = timeStr.split(':');
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final dingSec = m * 60 + s;

      if (dingSec == currentSec) {
        final int amount = isV2 ? (d as DingValueV2Data).dingAmount ?? 1 : (d as DingValueData).dingAmount ?? 1;
        String? audioOverride;
        if (isV2) {
          audioOverride = _dingV2AudioNames[(d as DingValueV2Data).id];
        }
        _playSound(timerId, amount, audioOverride: audioOverride);
      }
    }
  }

  Future<void> _playSound(int timerId, int amount, {String? audioOverride}) async {
    final fileName = audioOverride ?? _timerAudioFiles[timerId];
    if (fileName == null || fileName.isEmpty) return;

    final supportDir = await getApplicationSupportDirectory();
    final audioPath = p.join(AppConfig.dataPath(supportDir.path), 'ding', fileName);

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

  /// Uses a pool of AudioPlayers to minimize playback delay and support overlapping.
  void _spawnPlay(String audioPath) {
    final player = _dingPool[_nextPoolIndex];
    _nextPoolIndex = (_nextPoolIndex + 1) % _dingPool.length;
    
    // Stop and play again (this is faster than creating a new instance)
    player.stop().then((_) {
      player.play(DeviceFileSource(audioPath), volume: widget.dingVolume);
    });
  }

  void _toggleL() {
    if (_isRunningL) {
      _timerL?.cancel();
      setState(() => _isRunningL = false);
    } else {
      if (_secL > 0) {
        if (_isRunningR) {
          _timerR?.cancel();
          _isRunningR = false;
        }
        final tid = _timerIdsByType['doubleL'];
        if (tid != null) widget.onTimerInteracted?.call(tid);
        setState(() {
          _isRunningL = true;
          _isRunningR = _isRunningR; // ensure UI update for right timer if it was stopped
        });
        _timerL = async.Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secL > 0) {
            setState(() {
              _secL--;
              final tid = _timerIdsByType['doubleL'];
              if (tid != null) {
                widget.sessionTimerSeconds[tid] = _secL;
              }
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
        if (_isRunningL) {
          _timerL?.cancel();
          _isRunningL = false;
        }
        final tid = _timerIdsByType['doubleR'];
        if (tid != null) widget.onTimerInteracted?.call(tid);
        setState(() {
          _isRunningR = true;
          _isRunningL = _isRunningL; // ensure UI update for left timer if it was stopped
        });
        _timerR = async.Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_secR > 0) {
            setState(() {
              _secR--;
              final tid = _timerIdsByType['doubleR'];
              if (tid != null) {
                widget.sessionTimerSeconds[tid] = _secR;
              }
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

  Color _resolveColor(String? pageColor, String? flowColor, Color fallback) {
    String? hex = pageColor ?? flowColor;
    if (hex != null && hex.isNotEmpty) {
      try {
        return Color(int.parse(hex.replaceFirst('#', '0xFF')));
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  void _showManualTimeEntry(String type) {
    final currentVal =
        type == 'single' ? _secondsC : (type == 'doubleL' ? _secL : _secR);
    final mVal = currentVal ~/ 60;
    final sVal = currentVal % 60;

    final TextEditingController minController =
        TextEditingController(text: mVal.toString());
    final TextEditingController secController =
        TextEditingController(text: sVal.toString().padLeft(2, '0'));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动设置时间'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: minController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '分',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(':',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: secController,
                decoration: const InputDecoration(
                  labelText: '秒',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final m = int.tryParse(minController.text) ?? 0;
              final s = int.tryParse(secController.text) ?? 0;
              final total = m * 60 + s;

              setState(() {
                if (type == 'single') _secondsC = total;
                if (type == 'doubleL') _secL = total;
                if (type == 'doubleR') _secR = total;

                final tid = _timerIdsByType[type];
                if (tid != null) {
                  widget.sessionTimerSeconds[tid] = total;
                  widget.onTimerInteracted?.call(tid);
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF312E81),
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
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

          // Scale the content from the application's native screen bounds
          LayoutBuilder(builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 1920,
                height: 1080,
                child: Stack(
                  children: [
                    // Content
                    if (widget.pageData.pageTypeId != 'C')
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 100, horizontal: 100),
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
                                        (widget.pageData.pageTypeId == 'B'
                                            ? 0
                                            : 0)),
                                child: Transform.scale(
                                  scale: _sectionPos?.size ?? 1.0,
                                  child: Text(
                                    widget.pageData.sectionName ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _resolveColor(
                                          widget.pageData.sectionFontColor,
                                          widget.flow.sectionFontColor,
                                          Colors.black),
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      fontFamily:
                                          _pageSectionFont ?? widget.fontFamily,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.6),
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
                                          if (tid != null) {
                                            widget.sessionTimerSeconds[tid] =
                                                _secondsC;
                                            widget.onTimerInteracted?.call(tid);
                                          }
                                        });
                                      },
                                      isA2: false,
                                      type: 'single',
                                    ),
                                  ),
                                ),
                              ),

                            // Timer A2 Left
                            if (widget.pageData.pageTypeId == 'A2')
                              Align(
                                alignment: const Alignment(-0.5, 0.0),
                                child: Transform.translate(
                                  offset: Offset(
                                      _timerPos['doubleL']?.xpos ?? 0,
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
                                          final tid =
                                              _timerIdsByType['doubleL'];
                                          if (tid != null) {
                                            widget.sessionTimerSeconds[tid] =
                                                _secL;
                                            widget.onTimerInteracted?.call(tid);
                                          }
                                        });
                                      },
                                      isA2: true,
                                      type: 'doubleL',
                                    ),
                                  ),
                                ),
                              ),

                            // Timer A2 Right
                            if (widget.pageData.pageTypeId == 'A2')
                              Align(
                                alignment: const Alignment(0.5, 0.0),
                                child: Transform.translate(
                                  offset: Offset(
                                      _timerPos['doubleR']?.xpos ?? 0,
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
                                          final tid =
                                              _timerIdsByType['doubleR'];
                                          if (tid != null) {
                                            widget.sessionTimerSeconds[tid] =
                                                _secR;
                                            widget.onTimerInteracted?.call(tid);
                                          }
                                        });
                                      },
                                      isA2: true,
                                      type: 'doubleR',
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // School Info (Always show on all pages, matches PageManagerPage layout)
                    if (widget.pageData.showSchools ?? true)
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
              ),
            );
          }),
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
          return const SizedBox.shrink();
        }
        final path = p.join(AppConfig.dataPath(snapshot.data!.path), 'schools',
            widget.flow.eventId.toString(), logo!.imageName!);
        if (!File(path).existsSync()) {
          return const SizedBox.shrink();
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
    required String type,
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
        const SizedBox(width: 24),
        IconButton.filled(
          iconSize: controlSize,
          onPressed: () => _showManualTimeEntry(type),
          icon: const Icon(Icons.settings_rounded),
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
          color: _resolveColor(widget.pageData.timerFontColor,
              widget.flow.timerFontColor, Colors.black),
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

