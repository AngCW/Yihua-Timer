import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'page_config_dialog.dart';

class EditTimerFlowPage extends StatefulWidget {
  final String flowName;

  const EditTimerFlowPage({
    super.key,
    required this.flowName,
  });

  static Future<void> show(BuildContext context, String flowName) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: EditTimerFlowPage(flowName: flowName),
      ),
    );
  }

  @override
  State<EditTimerFlowPage> createState() => _EditTimerFlowPageState();
}

class _EditTimerFlowPageState extends State<EditTimerFlowPage> {
  final List<FlowCard> _flowCards = [];
  final List<FlowCard> _extraFlowCards = [];
  final TextEditingController _team1NameController = TextEditingController();
  final TextEditingController _team2NameController = TextEditingController();
  String? _team1LogoPath;
  String? _team2LogoPath;

  @override
  void initState() {
    super.initState();
    // Initialize with sample data
    _flowCards.addAll([
      FlowCard(name: '主页', pageType: 'C'),
      FlowCard(name: '计时器介绍', pageType: 'A2'),
      FlowCard(name: '3正 vs 3反', pageType: 'A2'),
    ]);
    _extraFlowCards.addAll([
      FlowCard(name: '断线缓冲', subtitle: '计时环节', pageType: 'C', shortcut: '1'),
      FlowCard(name: '断线缓冲', subtitle: '标题页面', pageType: 'B', shortcut: '2'),
      FlowCard(name: '立场捍卫', subtitle: '环节', pageType: 'C', shortcut: '3'),
      FlowCard(name: '资料检证', subtitle: '环节', pageType: 'C', shortcut: '4'),
    ]);
  }

  @override
  void dispose() {
    _team1NameController.dispose();
    _team2NameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.flowName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
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
                  // Team Info Section
                  _buildTeamInfoSection(),
                  const SizedBox(height: 24),
                  // Flow Section
                  _buildFlowSection(),
                  const SizedBox(height: 24),
                  // Extra Flow Section
                  _buildExtraFlowSection(),
                ],
              ),
            ),
          ),
          // Footer with buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    // TODO: Implement save functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('保存成功')),
                    );
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team 1
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '参赛队1:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _team1NameController,
                decoration: InputDecoration(
                  hintText: '请输入参赛队1名称',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '队伍校徽:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildLogoUploadField(1),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Team 2
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '参赛队2:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _team2NameController,
                decoration: InputDecoration(
                  hintText: '请输入参赛队2名称',
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '队伍校徽:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              _buildLogoUploadField(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoUploadField(int teamNumber) {
    final isTeam1 = teamNumber == 1;
    final logoPath = isTeam1 ? _team1LogoPath : _team2LogoPath;
    
    return InkWell(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          setState(() {
            if (isTeam1) {
              _team1LogoPath = result.files.single.path;
            } else {
              _team2LogoPath = result.files.single.path;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.upload_file,
              color: Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                logoPath != null
                    ? logoPath.split(Platform.pathSeparator).last
                    : '点击上传队伍校徽',
                style: TextStyle(
                  color: logoPath != null
                      ? Colors.grey.shade800
                      : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            if (logoPath != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey.shade600,
                onPressed: () {
                  setState(() {
                    if (isTeam1) {
                      _team1LogoPath = null;
                    } else {
                      _team2LogoPath = null;
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '流程:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._flowCards.map((card) => _buildFlowCard(card, false)),
                  _buildAddButton('添加流程', () {
                    setState(() {
                      _flowCards.add(FlowCard(name: '新流程', pageType: 'C'));
                    });
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExtraFlowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'extra 流程:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._extraFlowCards.map((card) => _buildFlowCard(card, true)),
                  _buildAddButton('添加流程', () {
                    setState(() {
                      _extraFlowCards.add(FlowCard(name: '新流程', pageType: 'C'));
                    });
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlowCard(FlowCard card, bool isExtra) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isExtra
                ? [
                    const Color(0xFF3B82F6).withOpacity(0.8),
                    const Color(0xFF3B82F6),
                  ]
                : [
                    const Color(0xFFF59E0B).withOpacity(0.8),
                    const Color(0xFFF59E0B),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (card.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                card.subtitle!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '页面类型: ${card.pageType}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            if (card.shortcut != null) ...[
              const SizedBox(height: 4),
              Text(
                '快键: ${card.shortcut}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  onPressed: () async {
                    final result = await PageConfigDialog.show(
                      context,
                      pageName: card.name,
                      pageType: card.pageType,
                    );
                    if (result != null) {
                      // Update the card with new values if needed
                      setState(() {
                        // You can update the card here if result contains updated data
                      });
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      if (isExtra) {
                        _extraFlowCards.remove(card);
                      } else {
                        _flowCards.remove(card);
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add,
                  color: Color(0xFF6B46C1),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class FlowCard {
  final String name;
  final String? subtitle;
  final String pageType;
  final String? shortcut;

  FlowCard({
    required this.name,
    this.subtitle,
    required this.pageType,
    this.shortcut,
  });
}
