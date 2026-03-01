class HotkeyBinding {
  final String id;
  final String label;
  String key;

  HotkeyBinding({
    required this.id,
    required this.label,
    required this.key,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'key': key,
      };

  factory HotkeyBinding.fromJson(Map<String, dynamic> json) {
    return HotkeyBinding(
      id: json['id'],
      label: json['label'],
      key: json['key'],
    );
  }

  HotkeyBinding copyWith({String? key}) {
    return HotkeyBinding(
      id: id,
      label: label,
      key: key ?? this.key,
    );
  }
}

class HotkeySettings {
  // General Controls
  final HotkeyBinding previousPage;
  final HotkeyBinding nextPage;
  final HotkeyBinding specialPage;

  // Page A1
  final HotkeyBinding pageA1StartStop;
  final HotkeyBinding pageA1Reset;

  // Page A2 - Left Timer
  final HotkeyBinding pageA2LeftStartStop;
  final HotkeyBinding pageA2LeftReset;

  // Page A2 - Right Timer
  final HotkeyBinding pageA2RightStartStop;
  final HotkeyBinding pageA2RightReset;

  // Page A2 - Common
  final HotkeyBinding pageA2Swap;

  HotkeySettings({
    required this.previousPage,
    required this.nextPage,
    required this.specialPage,
    required this.pageA1StartStop,
    required this.pageA1Reset,
    required this.pageA2LeftStartStop,
    required this.pageA2LeftReset,
    required this.pageA2RightStartStop,
    required this.pageA2RightReset,
    required this.pageA2Swap,
  });

  factory HotkeySettings.defaultSettings() {
    return HotkeySettings(
      previousPage: HotkeyBinding(
        id: 'general_previous',
        label: '转至上个页面:',
        key: 'ArrowLeft',
      ),
      nextPage: HotkeyBinding(
        id: 'general_next',
        label: '转至下个页面:',
        key: 'ArrowRight',
      ),
      specialPage: HotkeyBinding(
        id: 'general_special',
        label: '转至特别页面:',
        key: 'Special',
      ),
      pageA1StartStop: HotkeyBinding(
        id: 'page_a1_start_stop',
        label: '开始/停止 计时:',
        key: 'Q',
      ),
      pageA1Reset: HotkeyBinding(
        id: 'page_a1_reset',
        label: '重置计时:',
        key: 'A',
      ),
      pageA2LeftStartStop: HotkeyBinding(
        id: 'page_a2_left_start_stop',
        label: '开始/停止 计时:',
        key: 'Q',
      ),
      pageA2LeftReset: HotkeyBinding(
        id: 'page_a2_left_reset',
        label: '重置计时:',
        key: 'A',
      ),
      pageA2RightStartStop: HotkeyBinding(
        id: 'page_a2_right_start_stop',
        label: '开始/停止 计时:',
        key: 'E',
      ),
      pageA2RightReset: HotkeyBinding(
        id: 'page_a2_right_reset',
        label: '重置计时:',
        key: 'D',
      ),
      pageA2Swap: HotkeyBinding(
        id: 'page_a2_swap',
        label: '开始一端并停止另一端:',
        key: 'SPACE',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'previousPage': previousPage.toJson(),
        'nextPage': nextPage.toJson(),
        'specialPage': specialPage.toJson(),
        'pageA1StartStop': pageA1StartStop.toJson(),
        'pageA1Reset': pageA1Reset.toJson(),
        'pageA2LeftStartStop': pageA2LeftStartStop.toJson(),
        'pageA2LeftReset': pageA2LeftReset.toJson(),
        'pageA2RightStartStop': pageA2RightStartStop.toJson(),
        'pageA2RightReset': pageA2RightReset.toJson(),
        'pageA2Swap': pageA2Swap.toJson(),
      };

  factory HotkeySettings.fromJson(Map<String, dynamic> json) {
    return HotkeySettings(
      previousPage: HotkeyBinding.fromJson(json['previousPage']),
      nextPage: HotkeyBinding.fromJson(json['nextPage']),
      specialPage: HotkeyBinding.fromJson(json['specialPage']),
      pageA1StartStop: HotkeyBinding.fromJson(json['pageA1StartStop']),
      pageA1Reset: HotkeyBinding.fromJson(json['pageA1Reset']),
      pageA2LeftStartStop: HotkeyBinding.fromJson(json['pageA2LeftStartStop']),
      pageA2LeftReset: HotkeyBinding.fromJson(json['pageA2LeftReset']),
      pageA2RightStartStop:
          HotkeyBinding.fromJson(json['pageA2RightStartStop']),
      pageA2RightReset: HotkeyBinding.fromJson(json['pageA2RightReset']),
      pageA2Swap: json['pageA2Swap'] != null
          ? HotkeyBinding.fromJson(json['pageA2Swap'])
          : HotkeyBinding(
              id: 'page_a2_swap', label: '开始一端并停止另一端:', key: 'SPACE'),
    );
  }

  HotkeySettings copyWith({
    HotkeyBinding? previousPage,
    HotkeyBinding? nextPage,
    HotkeyBinding? specialPage,
    HotkeyBinding? pageA1StartStop,
    HotkeyBinding? pageA1Reset,
    HotkeyBinding? pageA2LeftStartStop,
    HotkeyBinding? pageA2LeftReset,
    HotkeyBinding? pageA2RightStartStop,
    HotkeyBinding? pageA2RightReset,
    HotkeyBinding? pageA2Swap,
  }) {
    return HotkeySettings(
      previousPage: previousPage ?? this.previousPage,
      nextPage: nextPage ?? this.nextPage,
      specialPage: specialPage ?? this.specialPage,
      pageA1StartStop: pageA1StartStop ?? this.pageA1StartStop,
      pageA1Reset: pageA1Reset ?? this.pageA1Reset,
      pageA2LeftStartStop: pageA2LeftStartStop ?? this.pageA2LeftStartStop,
      pageA2LeftReset: pageA2LeftReset ?? this.pageA2LeftReset,
      pageA2RightStartStop: pageA2RightStartStop ?? this.pageA2RightStartStop,
      pageA2RightReset: pageA2RightReset ?? this.pageA2RightReset,
      pageA2Swap: pageA2Swap ?? this.pageA2Swap,
    );
  }

  void updateBinding(String id, String newKey) {
    if (previousPage.id == id) {
      previousPage.key = newKey;
    } else if (nextPage.id == id) {
      nextPage.key = newKey;
    } else if (specialPage.id == id) {
      specialPage.key = newKey;
    } else if (pageA1StartStop.id == id) {
      pageA1StartStop.key = newKey;
    } else if (pageA1Reset.id == id) {
      pageA1Reset.key = newKey;
    } else if (pageA2LeftStartStop.id == id) {
      pageA2LeftStartStop.key = newKey;
    } else if (pageA2LeftReset.id == id) {
      pageA2LeftReset.key = newKey;
    } else if (pageA2RightStartStop.id == id) {
      pageA2RightStartStop.key = newKey;
    } else if (pageA2RightReset.id == id) {
      pageA2RightReset.key = newKey;
    } else if (pageA2Swap.id == id) {
      pageA2Swap.key = newKey;
    }
  }
}
