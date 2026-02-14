import 'package:flutter/material.dart';

class VolumeSettingsPage extends StatefulWidget {
  const VolumeSettingsPage({super.key});

  @override
  State<VolumeSettingsPage> createState() => _VolumeSettingsPageState();
}

class _VolumeSettingsPageState extends State<VolumeSettingsPage> {
  double _ringtoneVolume = 0.7;
  double _backgroundMusicVolume = 0.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringtone Volume Section
            _buildVolumeCard(
              title: '铃声',
              value: _ringtoneVolume,
              onChanged: (value) {
                setState(() {
                  _ringtoneVolume = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Background Music Volume Section
            _buildVolumeCard(
              title: '背景音乐',
              value: _backgroundMusicVolume,
              onChanged: (value) {
                setState(() {
                  _backgroundMusicVolume = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeCard({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6B46C1),
            inactiveColor: Colors.grey.shade300,
            min: 0.0,
            max: 1.0,
            divisions: 100,
          ),
        ],
      ),
    );
  }
}

