import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../EventManager/event_manager_page.dart';

class PageConfigDialog extends StatefulWidget {
  final String pageName;
  final String pageType;
  final String? sectionName;
  final String? timerATemplate;
  final String? timerBTemplate;
  final String? timerAStartTime;
  final String? timerBStartTime;
  final String? bgmPath;

  const PageConfigDialog({
    super.key,
    required this.pageName,
    required this.pageType,
    this.sectionName,
    this.timerATemplate,
    this.timerBTemplate,
    this.timerAStartTime,
    this.timerBStartTime,
    this.bgmPath,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String pageName,
    required String pageType,
    String? sectionName,
    String? timerATemplate,
    String? timerBTemplate,
    String? timerAStartTime,
    String? timerBStartTime,
    String? bgmPath,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: PageConfigDialog(
          pageName: pageName,
          pageType: pageType,
          sectionName: sectionName,
          timerATemplate: timerATemplate,
          timerBTemplate: timerBTemplate,
          timerAStartTime: timerAStartTime,
          timerBStartTime: timerBStartTime,
          bgmPath: bgmPath,
        ),
      ),
    );
  }

  @override
  State<PageConfigDialog> createState() => _PageConfigDialogState();
}

class _PageConfigDialogState extends State<PageConfigDialog> {
  late TextEditingController _pageNameController;
  late TextEditingController _pageTypeController;
  late TextEditingController _sectionNameController;
  late TextEditingController _timerAMinController;
  late TextEditingController _timerASecController;
  late TextEditingController _timerBMinController;
  late TextEditingController _timerBSecController;

  String? _selectedTimerATemplate;
  String? _selectedTimerBTemplate;
  String? _bgmPath;
  int _previewSecA = 0;
  int _previewSecB = 0;
  String _timerCount = '两个'; // 无, 一个, 两个

  double _sectionX = 0, _sectionY = 0, _sectionScale = 1.0;
  double _timerAX = 0, _timerAY = 0, _timerAScale = 1.0;
  double _timerBX = 0, _timerBY = 0, _timerBScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pageNameController = TextEditingController(text: widget.pageName);
    _pageTypeController = TextEditingController(text: widget.pageType);
    _sectionNameController =
        TextEditingController(text: widget.sectionName ?? '');

    // Listen to page type changes to update preview
    _pageTypeController.addListener(() {
      setState(() {});
    });

    // Parse timer A start time
    if (widget.timerAStartTime != null) {
      final parts = widget.timerAStartTime!.split(':');
      _timerAMinController =
          TextEditingController(text: parts.isNotEmpty ? parts[0] : '4');
      _timerASecController =
          TextEditingController(text: parts.length > 1 ? parts[1] : '00');
      _previewSecA = (int.tryParse(_timerAMinController.text) ?? 4) * 60 +
          (int.tryParse(_timerASecController.text) ?? 0);
    } else {
      _timerAMinController = TextEditingController(text: '4');
      _timerASecController = TextEditingController(text: '00');
      _previewSecA = 4 * 60;
    }

    // Parse timer B start time
    if (widget.timerBStartTime != null) {
      final parts = widget.timerBStartTime!.split(':');
      _timerBMinController =
          TextEditingController(text: parts.isNotEmpty ? parts[0] : '4');
      _timerBSecController =
          TextEditingController(text: parts.length > 1 ? parts[1] : '00');
      _previewSecB = (int.tryParse(_timerBMinController.text) ?? 4) * 60 +
          (int.tryParse(_timerBSecController.text) ?? 0);
    } else {
      _timerBMinController = TextEditingController(text: '4');
      _timerBSecController = TextEditingController(text: '00');
      _previewSecB = 4 * 60;
    }

    _selectedTimerATemplate = widget.timerATemplate ?? 'default';
    _selectedTimerBTemplate = widget.timerBTemplate ?? 'default';
    _bgmPath = widget.bgmPath;

    // Listeners to update preview
    _timerAMinController.addListener(_updatePreviewA);
    _timerASecController.addListener(_updatePreviewA);
    _timerBMinController.addListener(_updatePreviewB);
    _timerBSecController.addListener(_updatePreviewB);
  }

  void _updatePreviewA() {
    final min = int.tryParse(_timerAMinController.text) ?? 0;
    final sec = int.tryParse(_timerASecController.text) ?? 0;
    setState(() {
      _previewSecA = min * 60 + sec;
    });
  }

  void _updatePreviewB() {
    final min = int.tryParse(_timerBMinController.text) ?? 0;
    final sec = int.tryParse(_timerBSecController.text) ?? 0;
    setState(() {
      _previewSecB = min * 60 + sec;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pageNameController.dispose();
    _pageTypeController.dispose();
    _sectionNameController.dispose();
    _timerAMinController.dispose();
    _timerASecController.dispose();
    _timerBMinController.dispose();
    _timerBSecController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with back button and save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FilledButton(
                  onPressed: () async {
                    // Close the dialog first
                    Navigator.of(context).pop({
                      'pageName': _pageNameController.text,
                      'pageType': _pageTypeController.text.toUpperCase(),
                      'sectionName': _sectionNameController.text,
                      'timerATemplate': _selectedTimerATemplate,
                      'timerBTemplate': _selectedTimerBTemplate,
                      'timerAStartTime':
                          '${_timerAMinController.text}:${_timerASecController.text}',
                      'timerBStartTime':
                          '${_timerBMinController.text}:${_timerBSecController.text}',
                      'bgmPath': _bgmPath,
                      'sectionX': _sectionX,
                      'sectionY': _sectionY,
                      'sectionScale': _sectionScale,
                      'timerAX': _timerAX,
                      'timerAY': _timerAY,
                      'timerAScale': _timerAScale,
                      'timerBX': _timerBX,
                      'timerBY': _timerBY,
                      'timerBScale': _timerBScale,
                    });

                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('保存成功'),
                          backgroundColor: Color(0xFF6B46C1),
                          duration: Duration(seconds: 2),
                        ),
                      );

                      // Wait a bit for the message to be visible, then navigate
                      await Future.delayed(const Duration(milliseconds: 500));

                      // Pop all dialogs and routes until we reach the dashboard
                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);

                        // Navigate to EventManagerPage (已保存赛事)
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const EventManagerPage(),
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Name
                  _buildLabel('页面名字:'),
                  const SizedBox(height: 8),
                  _buildTextField(_pageNameController, '请输入页面名字'),
                  const SizedBox(height: 24),

                  // Page Type
                  _buildLabel('页面类型:'),
                  const SizedBox(height: 8),
                  _buildTextField(
                      _pageTypeController, '请输入页面类型 (A1, A2, B, C)'),
                  const SizedBox(height: 24),

                  // Section Name
                  _buildLabel('阶段标题:'),
                  const SizedBox(height: 8),
                  _buildTextField(_sectionNameController, '例如: 正方三辩 反方三辩 对辩环节'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: _buildPositionRow(
                      '阶段标题位置',
                      _sectionX,
                      _sectionY,
                      _sectionScale,
                      (val) => setState(() => _sectionX = val),
                      (val) => setState(() => _sectionY = val),
                      (val) => setState(() => _sectionScale = val),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timer Count Toggle
                  _buildLabel('计时器:'),
                  const SizedBox(height: 8),
                  _buildTimerCountSelector(),
                  const SizedBox(height: 24),

                  // Timer - show based on selection
                  if (_timerCount == '一个') ...[
                    _buildTimerBox('计时器(中间)', true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: _buildPositionRow(
                        '计时器位置',
                        _timerAX,
                        _timerAY,
                        _timerAScale,
                        (val) => setState(() => _timerAX = val),
                        (val) => setState(() => _timerAY = val),
                        (val) => setState(() => _timerAScale = val),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else if (_timerCount == '两个') ...[
                    _buildTimerBox('计时器A (左边)', true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: _buildPositionRow(
                        '计时器A位置',
                        _timerAX,
                        _timerAY,
                        _timerAScale,
                        (val) => setState(() => _timerAX = val),
                        (val) => setState(() => _timerAY = val),
                        (val) => setState(() => _timerAScale = val),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTimerBox('计时器B (右边)', false),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: _buildPositionRow(
                        '计时器B位置',
                        _timerBX,
                        _timerBY,
                        _timerBScale,
                        (val) => setState(() => _timerBX = val),
                        (val) => setState(() => _timerBY = val),
                        (val) => setState(() => _timerBScale = val),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Background Music
                  _buildLabel('背景音乐:'),
                  const SizedBox(height: 8),
                  _buildBgmUploadField(),
                  const SizedBox(height: 24),

                  // Position Section removed and moved above

                  // Preview
                  _buildLabel('preview:'),
                  const SizedBox(height: 12),
                  _buildPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildTimerCountSelector() {
    return Row(
      children: [
        _buildTimerCountOption('无'),
        const SizedBox(width: 12),
        _buildTimerCountOption('一个'),
        const SizedBox(width: 12),
        _buildTimerCountOption('两个'),
      ],
    );
  }

  Widget _buildTimerCountOption(String value) {
    final isSelected = _timerCount == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _timerCount = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B46C1) : Colors.white,
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF6B46C1) : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBox(String title, bool isTimerA) {
    final minController =
        isTimerA ? _timerAMinController : _timerBMinController;
    final secController =
        isTimerA ? _timerASecController : _timerBSecController;
    final template =
        isTimerA ? _selectedTimerATemplate : _selectedTimerBTemplate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '铃声template:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: template,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: ['default', 'template1', 'template2']
                .map((t) => DropdownMenuItem<String>(
                      value: t,
                      child: Text(t),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                if (isTimerA) {
                  _selectedTimerATemplate = val;
                } else {
                  _selectedTimerBTemplate = val;
                }
              });
            },
          ),
          const SizedBox(height: 8),
          const Text(
            '开始时间:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(fontSize: 20, color: Color(0xFF111827)),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: secController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBgmUploadField() {
    return InkWell(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          setState(() {
            _bgmPath = result.files.single.path;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, color: Color(0xFF6B46C1)),
            const SizedBox(width: 8),
            Text(
              _bgmPath != null
                  ? _bgmPath!.split(Platform.pathSeparator).last
                  : '(一样可以drag and drop)',
              style: TextStyle(
                color: _bgmPath != null
                    ? Colors.grey.shade800
                    : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final pageType = _pageTypeController.text.toUpperCase();
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.green.shade700, // Green preview background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Section Name
          if (pageType != 'C')
            Align(
              alignment:
                  pageType == 'B' ? Alignment.center : Alignment.topCenter,
              child: Transform.translate(
                offset:
                    Offset(_sectionX, _sectionY + (pageType == 'B' ? 0 : 50)),
                child: Transform.scale(
                  scale: _sectionScale,
                  child: Text(
                    _sectionNameController.text.isEmpty
                        ? '阶段标题预览'
                        : _sectionNameController.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: pageType == 'B' ? 36 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Timer A
          if (_timerCount == '一个')
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(_timerAX, _timerAY - 50),
                child: Transform.scale(
                  scale: _timerAScale,
                  child: Text(
                    _formatTime(_previewSecA),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Timer A - left side (if 两个)
          if (_timerCount == '两个')
            Align(
              alignment: const Alignment(-0.6, 0.4),
              child: Transform.translate(
                offset: Offset(_timerAX, _timerAY),
                child: Transform.scale(
                  scale: _timerAScale,
                  child: Text(
                    _formatTime(_previewSecA),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Timer B - right side (if 两个)
          if (_timerCount == '两个')
            Align(
              alignment: const Alignment(0.6, 0.4),
              child: Transform.translate(
                offset: Offset(_timerBX, _timerBY),
                child: Transform.scale(
                  scale: _timerBScale,
                  child: Text(
                    _formatTime(_previewSecB),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPositionRow(
    String label,
    double x,
    double y,
    double scale,
    ValueChanged<double> onX,
    ValueChanged<double> onY,
    ValueChanged<double> onScale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMiniPosInput('X', x, onX),
            const SizedBox(width: 8),
            _buildMiniPosInput('Y', y, onY),
            const SizedBox(width: 8),
            _buildMiniPosInput('Size', scale, onScale, isScale: true),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniPosInput(
      String label, double value, ValueChanged<double> onChanged,
      {bool isScale = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
              controller: TextEditingController(
                  text: value.toStringAsFixed(isScale ? 2 : 0))
                ..selection = TextSelection.fromPosition(TextPosition(
                    offset: value.toStringAsFixed(isScale ? 2 : 0).length)),
              onSubmitted: (val) {
                final d = double.tryParse(val);
                if (d != null) onChanged(d);
              },
            ),
          ),
        ],
      ),
    );
  }
}
