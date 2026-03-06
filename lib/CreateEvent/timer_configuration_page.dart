import 'package:flutter/material.dart';
import 'edit_timer_flow_page.dart';

class TimerConfigurationPage extends StatefulWidget {
  final String? ringtoneFileName;
  final bool isDefaultTemplate;
  final VoidCallback? onBack;

  const TimerConfigurationPage({
    super.key,
    this.ringtoneFileName,
    this.isDefaultTemplate = false,
    this.onBack,
  });

  @override
  State<TimerConfigurationPage> createState() => _TimerConfigurationPageState();
}

class _TimerConfigurationPageState extends State<TimerConfigurationPage> {
  // List to store timer flows
  late List<String> _timerFlows;

  @override
  void initState() {
    super.initState();
    // Initialize with default flows if using default template
    _timerFlows = widget.isDefaultTemplate
        ? ['初赛A', '初赛B', '16强A']
        : [];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth > 0 ? constraints.maxWidth : 800,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button and save button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onBack ?? () {},
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('返回'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B46C1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        // TODO: Implement save functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('保存成功')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 10,
                        ),
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
                const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '计时器铃声模板',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '配置计时器使用的铃声模板',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRingtoneTemplates(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '计时器流程',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '配置计时器的流程和阶段',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTimerFlows(context),
                ],
              ),
            ),
          ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRingtoneTemplates() {
    final templates = widget.isDefaultTemplate
        ? ['default']
        : widget.ringtoneFileName != null && widget.ringtoneFileName!.isNotEmpty
            ? [widget.ringtoneFileName!]
            : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        return SizedBox(
          width: availableWidth,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...templates.map((template) => _buildTemplateCard(template)),
              _buildAddButton(context, '添加模板', isTimerFlow: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerFlows(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        return SizedBox(
          width: availableWidth,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._timerFlows.map((flow) => _buildFlowCard(context, flow)),
              _buildAddButton(context, '添加流程', isTimerFlow: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateCard(String name) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6B46C1).withOpacity(0.8),
              const Color(0xFF6B46C1),
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
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                  onPressed: () {},
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

  Widget _buildFlowCard(BuildContext context, String name) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6B46C1).withOpacity(0.8),
              const Color(0xFF6B46C1),
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
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  onPressed: () {
                    EditTimerFlowPage.show(context, name);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                  onPressed: () {},
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

  Widget _buildAddButton(BuildContext context, String label, {bool isTimerFlow = true}) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: isTimerFlow ? () => _showAddFlowDialog(context) : null,
        borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 20), // Match text height
              const SizedBox(height: 12), // Match spacing
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
              const SizedBox(height: 18), // Match icon button row height
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFlowDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('添加计时器流程'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '计时器流程名称',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: '请输入流程名称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                nameController.dispose();
              },
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final flowName = nameController.text.trim();
                if (flowName.isNotEmpty) {
                  setState(() {
                    _timerFlows.add(flowName);
                  });
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已添加流程: $flowName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                nameController.dispose();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
}

