import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<int> _intervalOptions = [1, 15, 30, 45, 60, 90, 120];
  final List<String> _soundOptions = ['notification.mp3', 'bell.mp3', 'chime.mp3'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lucid Reminder'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEnableSwitch(settings),
                const SizedBox(height: 24),
                _buildIntervalSelector(settings),
                const SizedBox(height: 24),
                _buildSoundSelector(settings),
                const SizedBox(height: 32),
                _buildInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnableSwitch(SettingsProvider settings) {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: const Text(
          'Enable Reality Checks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          settings.isEnabled ? 'Reality checks are active' : 'Reality checks are paused',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        value: settings.isEnabled,
        onChanged: (value) async {
          await settings.setEnabled(value);
          if (value) {
            await NotificationService().scheduleRealityCheck(
              settings.intervalMinutes,
              settings.selectedSound,
            );
          } else {
            await NotificationService().stopNotifications();
          }
        },
      ),
    );
  }

  Widget _buildIntervalSelector(SettingsProvider settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check Interval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _intervalOptions.map((minutes) {
                return ChoiceChip(
                  label: Text('$minutes min'),
                  selected: settings.intervalMinutes == minutes,
                  onSelected: (selected) async {
                    if (selected) {
                      await settings.setIntervalMinutes(minutes);
                      if (settings.isEnabled) {
                        await NotificationService().scheduleRealityCheck(
                          minutes,
                          settings.selectedSound,
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelector(SettingsProvider settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Sound',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _soundOptions.map((sound) {
                return ChoiceChip(
                  label: Text(sound.split('.').first),
                  selected: settings.selectedSound == sound,
                  onSelected: (selected) async {
                    if (selected) {
                      await settings.setSelectedSound(sound);
                      await NotificationService().playSound(sound);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Column(
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Reality Check Guide',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Look at your hands\n'
                  '2. Try to push your finger through your palm\n'
                  '3. Check if you can breathe with your nose closed\n'
                  '4. Look at text or numbers twice\n'
                  '5. Question your surroundings',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Important Notice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'For reliable notifications while the screen is off:\n'
                  '1. Disable battery optimization for this app\n'
                  '2. Allow background running\n'
                  '3. Keep the app running in background\n\n'
                  'Note: Notifications won\'t work if the phone is completely turned off.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 