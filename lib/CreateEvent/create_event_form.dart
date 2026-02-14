import 'package:debate_timer/models/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CreateEventPage extends StatelessWidget {
  const CreateEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreateEventForm(),
        ],
      ),
    );
  }
}

class CreateEventForm extends StatefulWidget {
  const CreateEventForm({super.key});

  @override
  State<CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _dateController = TextEditingController();
  final _teamNumController = TextEditingController();
  final _bgImgNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _teamNumController.dispose();
    _bgImgNameController.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      EventModel newEvent = EventModel(
          name: _nameController.text,
          desc: _descController.text,
          date: DateTime.parse(_dateController.text),
          teamNum: int.parse(_teamNumController.text),
          bgImgName: _bgImgNameController.text);
      print("saved form value to model");

      newEvent.saveToDevice();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event saved to device')),
      );
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

    Widget _uploadButton(String label) {
      return SizedBox(
        width: 260,
        child: OutlinedButton.icon(
          onPressed: () {},
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
          ),
        ),
      );
    }

    return Form(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '自定义赛事',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              ////
              const SizedBox(height: 4),
              ////
              Text(
                '根据需求自定义计时赛程与页面',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              ////
              const SizedBox(height: 30),
              ////
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text('赛事名称', style: textStyleLabel),
                ),
              ),
              ////
              const SizedBox(height: 30),
              ////
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text('赛制简介', style: textStyleLabel),
                ),
              ),
              ////
              const SizedBox(height: 30),
              ////
              SizedBox(
                  width: 260,
                  child: TextFormField(
                    mouseCursor: SystemMouseCursors.click,
                      readOnly: true,
                      controller: _dateController,
                      decoration: _inputDecoration('请选择日期').copyWith(
                          suffixIcon: const Icon(Icons.calendar_today_rounded,
                              size: 18)),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100));

                        if (pickedDate == null) return;
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (pickedTime == null) return;

                        setState(() {
                          _selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute);

                          _dateController.text = DateFormat('yyyy-MM-dd HH:mm')
                              .format(_selectedDate);
                        });
                      })),
              ////
              const SizedBox(height: 30),
              ////
              TextFormField(
                controller: _teamNumController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text('参赛队数量', style: textStyleLabel),
                ),
              ),
              const SizedBox(height: 24),
              Text('投票数据表', style: textStyleLabel),
              const SizedBox(height: 6),
              _uploadButton('点击上传'),
              const SizedBox(height: 16),
              Text('音效文件', style: textStyleLabel),
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
                maxLines: 2,
                decoration: _inputDecoration('补充说明、特殊赛制要求等'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '下一步',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      '保存',
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
