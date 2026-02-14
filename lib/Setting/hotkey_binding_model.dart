class HotkeyBinding {
  final String id;
  final String label;
  String key;

  HotkeyBinding({
    required this.id,
    required this.label,
    required this.key,
  });

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
    );
  }

  void updateBinding(String id, String newKey) {
    // This method would be used to update a specific binding
    // Implementation depends on how you want to handle updates
  }
}

