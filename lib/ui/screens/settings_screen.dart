import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _audioQuality = 'High';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Audio Quality'),
            subtitle: Text(_audioQuality),
            leading: const Icon(Icons.high_quality),
            onTap: () {
              _showQualityDialog();
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear Cache'),
            leading: const Icon(Icons.delete_sweep),
            onTap: () {
              // Implementation for cache clearing
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('About Nirvay'),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Nirvay',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.music_note, size: 50, color: Colors.red),
                children: [
                  const Text('A pure Dart/Flutter music application with YouTube and JioSaavn support.'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Audio Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Eco (64kbps)', 'Normal (128kbps)', 'High (320kbps)'].map((quality) {
            return RadioListTile<String>(
              title: Text(quality),
              value: quality,
              groupValue: _audioQuality,
              onChanged: (value) {
                setState(() {
                  _audioQuality = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
