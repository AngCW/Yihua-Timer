import 'package:flutter/material.dart';

class CreateEventForm extends StatelessWidget {
  const CreateEventForm({super.key});

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          onPressed: () {
          },
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '自定义赛制',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    // Handle default format button
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: const BorderSide(color: Color(0xFF6B46C1)),
                    foregroundColor: const Color(0xFF6B46C1),
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
            const SizedBox(height: 4),
            Text(
              '根据需求自定义计时赛程与页面',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),

            Text('赛事名称', style: textStyleLabel),
            const SizedBox(height: 6),
            TextField(
              decoration: _inputDecoration('请输入赛事名称'),
            ),
            const SizedBox(height: 16),

            Text('赛制简介', style: textStyleLabel),
            const SizedBox(height: 6),
            TextField(
              decoration: _inputDecoration('简单描述本次赛事或赛制'),
            ),
            const SizedBox(height: 16),

            Text('赛事日期', style: textStyleLabel),
            const SizedBox(height: 6),
            SizedBox(
              width: 260,
              child: TextField(
                readOnly: true,
                decoration: _inputDecoration('请选择日期').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('参赛队数量', style: textStyleLabel),
            const SizedBox(height: 6),
            SizedBox(
              width: 160,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('例如：2'),
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
                  onPressed: () {
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
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
                  onPressed: () {
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
    );
  }
}

class CreateEventPage extends StatelessWidget {
  const CreateEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CreateEventForm(),
        ],
      ),
    );
  }
}

