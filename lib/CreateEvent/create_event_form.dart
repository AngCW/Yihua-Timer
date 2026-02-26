import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'timer_configuration_page.dart';
import 'package:drift/drift.dart' as drift;
import '../main.dart';
import '../database/app_database.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  int _currentStep = 0; // 0: form, 1: timer config
  String? _ringtoneFileName;
  bool _isDefaultTemplate = false;

  void _navigateToTimerConfig(
      String? ringtoneFileName, bool isDefaultTemplate) {
    setState(() {
      _currentStep = 1;
      _ringtoneFileName = ringtoneFileName;
      _isDefaultTemplate = isDefaultTemplate;
    });
  }

  void _goBackToForm() {
    setState(() {
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 1) {
      return TimerConfigurationPage(
        ringtoneFileName: _ringtoneFileName,
        isDefaultTemplate: _isDefaultTemplate,
        onBack: _goBackToForm,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreateEventForm(
            onNext: (ringtoneFileName) =>
                _navigateToTimerConfig(ringtoneFileName, false),
            onDefaultTemplate: () => _navigateToTimerConfig(null, true),
          ),
        ],
      ),
    );
  }
}

class CreateEventForm extends StatefulWidget {
  final Function(String?) onNext;
  final VoidCallback onDefaultTemplate;

  const CreateEventForm({
    super.key,
    required this.onNext,
    required this.onDefaultTemplate,
  });

  @override
  State<CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  final _dateController = TextEditingController();
  final _teamNumController = TextEditingController();
  final _bgImgNameController = TextEditingController();
  final _remarkController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _teamNumController.dispose();
    _bgImgNameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  bool _validateMandatoryFields() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入赛事名称')),
      );
      return false;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入赛制简介')),
      );
      return false;
    }
    if (_dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择日期')),
      );
      return false;
    }
    return true;
  }

  void _submitData() async {
    if (_formKey.currentState!.validate() && _validateMandatoryFields()) {
      try {
        final companion = EventCompanion(
          eventName: drift.Value(_nameController.text),
          eventDesc: drift.Value(_descController.text),
          startDate: drift.Value(_selectedDateRange?.start),
          endDate: drift.Value(_selectedDateRange?.end),
          teamNum: drift.Value(int.tryParse(_teamNumController.text)),
          remark: drift.Value(_remarkController.text),
        );

        await database.into(database.event).insert(companion);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('赛事已成功保存到数据库')),
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
  }

  @override
  Widget build(BuildContext context) {
    final textStyleLabel = TextStyle(
      fontSize: 14,
      color: Colors.grey.shade700,
    );

    InputDecoration _inputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 1.2),
        ),
      );
    }

    Widget _uploadButton(String label, {VoidCallback? onUpload}) {
      return SizedBox(
        width: 260,
        child: OutlinedButton.icon(
          onPressed: onUpload ?? () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: BorderSide(color: Colors.grey.shade300),
            foregroundColor: const Color(0xFF374151),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '自定义赛事',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (_validateMandatoryFields()) {
                        widget.onDefaultTemplate();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '默认赛制',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              ////
              const SizedBox(height: 4),
              ////
              Text(
                '根据需求自定义赛事信息',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              ////
              const SizedBox(height: 30),
              ////
              Text('赛事名称', style: textStyleLabel),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入赛事名称';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '请输入赛事名称',
                ),
              ),
              ////
              const SizedBox(height: 24),
              ////
              Text('赛制简介', style: textStyleLabel),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入赛制简介';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '简单描述本次赛事或赛制',
                ),
              ),
              ////
              const SizedBox(height: 24),
              ////
              Text('赛事日期', style: textStyleLabel),
              const SizedBox(height: 6),
              SizedBox(
                  width: 260,
                  child: TextFormField(
                      mouseCursor: SystemMouseCursors.click,
                      readOnly: true,
                      controller: _dateController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请选择日期';
                        }
                        return null;
                      },
                      decoration: _inputDecoration('请选择日期').copyWith(
                          suffixIcon: const Icon(Icons.calendar_today_rounded,
                              size: 18)),
                      onTap: () async {
                        DateTime? startDate = _selectedDateRange?.start;
                        DateTime? endDate = _selectedDateRange?.end;

                        final result = await showDialog<DateTimeRange>(
                          context: context,
                          builder: (dialogContext) => StatefulBuilder(
                            builder: (context, setDialogState) => Dialog(
                              child: Container(
                                width: 500,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          '选择日期范围',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () =>
                                              Navigator.of(dialogContext).pop(),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '开始日期',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              InkWell(
                                                onTap: () async {
                                                  final date =
                                                      await showDatePicker(
                                                    context: context,
                                                    initialDate: startDate ??
                                                        DateTime.now(),
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                                  if (date != null) {
                                                    setDialogState(() {
                                                      startDate = date;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        startDate != null
                                                            ? DateFormat(
                                                                    'yyyy-MM-dd')
                                                                .format(
                                                                    startDate!)
                                                            : '选择开始日期',
                                                        style: TextStyle(
                                                          color:
                                                              startDate != null
                                                                  ? Colors.black
                                                                  : Colors.grey,
                                                        ),
                                                      ),
                                                      const Icon(
                                                          Icons.calendar_today,
                                                          size: 18),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '结束日期',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              InkWell(
                                                onTap: () async {
                                                  final date =
                                                      await showDatePicker(
                                                    context: context,
                                                    initialDate: endDate ??
                                                        (startDate ??
                                                            DateTime.now()),
                                                    firstDate: startDate ??
                                                        DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                                  if (date != null) {
                                                    setDialogState(() {
                                                      endDate = date;
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        endDate != null
                                                            ? DateFormat(
                                                                    'yyyy-MM-dd')
                                                                .format(
                                                                    endDate!)
                                                            : '选择结束日期',
                                                        style: TextStyle(
                                                          color: endDate != null
                                                              ? Colors.black
                                                              : Colors.grey,
                                                        ),
                                                      ),
                                                      const Icon(
                                                          Icons.calendar_today,
                                                          size: 18),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dialogContext).pop(),
                                          child: const Text('取消'),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton(
                                          onPressed: () {
                                            if (startDate != null &&
                                                endDate != null) {
                                              Navigator.of(dialogContext).pop(
                                                DateTimeRange(
                                                    start: startDate!,
                                                    end: endDate!),
                                              );
                                            }
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF6B46C1),
                                          ),
                                          child: const Text('确定'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        if (result == null) return;

                        setState(() {
                          _selectedDateRange = result;
                          _dateController.text =
                              '${DateFormat('yyyy-MM-dd').format(result.start)} - ${DateFormat('yyyy-MM-dd').format(result.end)}';
                        });
                      })),
              ////
              const SizedBox(height: 24),
              ////
              Text('参赛队数量', style: textStyleLabel),
              const SizedBox(height: 6),
              TextFormField(
                controller: _teamNumController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '例如: 2',
                ),
              ),
              const SizedBox(height: 24),
              Text('投票数据表', style: textStyleLabel),
              const SizedBox(height: 6),
              _uploadButton('点击上传'),
              const SizedBox(height: 16),
              Text('背景音乐', style: textStyleLabel),
              const SizedBox(height: 6),
              _uploadButton('点击上传'),
              const SizedBox(height: 16),
              Text('背景图', style: textStyleLabel),
              const SizedBox(height: 6),
              _uploadButton('点击上传'),
              const SizedBox(height: 24),
              Text('备注', style: textStyleLabel),
              const SizedBox(height: 6),
              TextField(
                controller: _remarkController,
                maxLines: 2,
                decoration: _inputDecoration('补充说明、特殊赛制要求等'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: _submitData,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text(
                      '保存赛事',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          _validateMandatoryFields()) {
                        widget.onNext(null);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '下一步 (赛制配置)',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
