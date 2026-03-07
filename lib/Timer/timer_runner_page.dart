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
  bool _isLoading = true;
  String? _imagesDirPath;
  String? _fontFamily;
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

    // Load custom font if available
    if (widget.flow.fontName != null && widget.flow.fontName!.isNotEmpty) {
      final fontFile = File(p.join(imagesDir.path, widget.flow.fontName!));
      if (await fontFile.exists()) {
        final fontLoader = FontLoader(widget.flow.fontName!);
        fontLoader.addFont(
            Future.value(fontFile.readAsBytesSync().buffer.asByteData()));
        await fontLoader.load();
        _fontFamily = widget.flow.fontName;
      }
    }

    final pages = await (database.select(database.page)
          ..where((t) => t.flowId.equals(widget.flow.id))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.pagePosition)]))
        .get();

    if (mounted) {
      setState(() {
        _pages = pages;
        _isLoading = false;
      });
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
          if (event is KeyDownEvent && _hotkeySettings != null) {
            final key =
                event.logicalKey.keyLabel.toUpperCase().replaceAll('KEY ', '');

            if (key == _hotkeySettings!.previousPage.key.toUpperCase()) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              return KeyEventResult.handled;
            } else if (key == _hotkeySettings!.nextPage.key.toUpperCase()) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              return KeyEventResult.handled;
            } else if (key == 'ESCAPE') {
              Navigator.pop(context);
              return KeyEventResult.handled;
            } else {
              _keyStreamController.add(key);
              return KeyEventResult.handled;
            }
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
                  hotkeys: _hotkeySettings,
                );
              },
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
  final HotkeySettings? hotkeys;

  const _TimerPageView({
    required this.pageData,
    required this.pageIndex,
    required this.pageController,
    required this.keyStream,
    required this.flow,
    this.imagesDirPath,
    this.fontFamily,
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

  @override
  void initState() {
    super.initState();
    _loadTimers();
    _keySub = widget.keyStream.listen(_onKey);
  }

  void _onKey(String key) {
    if (!mounted) return;

    // Check if this page is active
    if (widget.pageController.hasClients) {
      final currentPage = widget.pageController.page?.round() ??
          widget.pageController.initialPage;
      if (currentPage != widget.pageIndex) return;
    } else {
      if (widget.pageIndex != 0) return;
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
        });
      } else if (key ==
          widget.hotkeys!.pageA2RightStartStop.key.toUpperCase()) {
        _toggleR();
      } else if (key == widget.hotkeys!.pageA2RightReset.key.toUpperCase()) {
        _timerR?.cancel();
        setState(() {
          _isRunningR = false;
          _secR = _initSecR;
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
      final totalSec = m * 60 + s;

      if (t.timerType == 'single') {
        _initSecC = totalSec;
        _secondsC = totalSec;
      } else if (t.timerType == 'doubleL') {
        _initSecL = totalSec;
        _secL = totalSec;
      } else if (t.timerType == 'doubleR') {
        _initSecR = totalSec;
        _secR = totalSec;
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
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
            setState(() => _secondsC--);
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
    final timers = await (database.select(database.timer)
          ..where((t) => t.pageId.equals(widget.pageData.id))
          ..where((t) => t.timerType.equals(type)))
        .get();

    for (var t in timers) {
      final dings = _dingValues[t.id] ?? [];
      for (var d in dings) {
        final parts = (d.dingTime ?? '0:0').split(':');
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final dingSec = m * 60 + s;

        if (dingSec == currentSec) {
          _playSound(t.id, d.dingAmount ?? 1);
        }
      }
    }
  }

  Future<void> _playSound(int timerId, int amount) async {
    final fileName = _timerAudioFiles[timerId];
    if (fileName == null || fileName.isEmpty) return;

    final supportDir = await getApplicationSupportDirectory();
    final audioPath = p.join(supportDir.path, 'YiHuaTimer', 'images',
        '${widget.flow.eventId}', fileName);

    if (await File(audioPath).exists()) {
      for (int i = 0; i < amount; i++) {
        await _audioPlayer.play(DeviceFileSource(audioPath));
        if (amount > 1) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    }
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
            setState(() => _secL--);
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
            setState(() => _secR--);
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
                    child: Text(
                      widget.pageData.sectionName ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: widget.fontFamily,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Timer A1
                  if (widget.pageData.pageTypeId == 'A1')
                    Align(
                      alignment: Alignment.center,
                      child: _buildTimerWidget(
                        time: _secondsC,
                        isRunning: _isRunning,
                        onToggle: _toggleC,
                        onReset: () {
                          _timerC?.cancel();
                          setState(() {
                            _isRunning = false;
                            _secondsC = _initSecC;
                          });
                        },
                        isA2: false,
                      ),
                    ),

                  // Timer A2
                  if (widget.pageData.pageTypeId == 'A2')
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimerWidget(
                            time: _secL,
                            isRunning: _isRunningL,
                            onToggle: _toggleL,
                            onReset: () {
                              _timerL?.cancel();
                              setState(() {
                                _isRunningL = false;
                                _secL = _initSecL;
                              });
                            },
                            isA2: true,
                          ),
                          _buildTimerWidget(
                            time: _secR,
                            isRunning: _isRunningR,
                            onToggle: _toggleR,
                            onReset: () {
                              _timerR?.cancel();
                              setState(() {
                                _isRunningR = false;
                                _secR = _initSecR;
                              });
                            },
                            isA2: true,
                            isRight: true,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
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
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          iconSize: isA2 ? 48 : 64,
          onPressed: onToggle,
          icon:
              Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          style: IconButton.styleFrom(backgroundColor: Colors.white12),
        ),
        const SizedBox(width: 24),
        IconButton.filled(
          iconSize: isA2 ? 48 : 64,
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(backgroundColor: Colors.white12),
        ),
      ],
    );

    final timerText = Text(
      _format(time),
      style: TextStyle(
        color: Colors.white,
        fontSize: isA2 ? 140 : 200,
        fontWeight: FontWeight.bold,
        fontFamily: widget.fontFamily,
        fontFeatures: const [ui.FontFeature.tabularFigures()],
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
    );

    if (isA2) {
      if (isRight) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            controls,
            const SizedBox(width: 32),
            timerText,
          ],
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            timerText,
            const SizedBox(width: 32),
            controls,
          ],
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        timerText,
        const SizedBox(height: 24),
        controls,
      ],
    );
  }
}
