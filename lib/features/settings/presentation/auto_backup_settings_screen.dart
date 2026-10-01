import 'package:flutter/material.dart';
import '../../../core/services/auto_backup_service.dart';
import '../../../core/database/database_helper.dart';
import '../../../shared/theme/app_theme.dart';

class AutoBackupSettingsScreen extends StatefulWidget {
  const AutoBackupSettingsScreen({super.key});

  @override
  State<AutoBackupSettingsScreen> createState() => _AutoBackupSettingsScreenState();
}

class _AutoBackupSettingsScreenState extends State<AutoBackupSettingsScreen> {
  bool _isEnabled = false;
  int _interval = 6;
  String _lastBackup = 'Jamais';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isEnabled = AutoBackupService.isEnabled();
    _interval = AutoBackupService.getInterval();
    _lastBackup = AutoBackupService.getLastBackupTimeString();
    setState(() {});
  }

  Future<void> _toggleBackup(bool value) async {
    await AutoBackupService.setEnabled(value);
    setState(() {
      _isEnabled = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '✅ Sauvegarde automatique activée' : '❌ Sauvegarde automatique désactivée'),
        backgroundColor: value ? AppTheme.successGreen : AppTheme.warningOrange,
      ),
    );
  }

  Future<void> _changeInterval(int hours) async {
    await AutoBackupService.setInterval(hours);
    setState(() {
      _interval = hours;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏱️ Intervalle: $hours heures'),
        backgroundColor: AppTheme.primaryGold,
      ),
    );
  }

  Future<void> _backupNow() async {
    setState(() {});
    try {
      final db = DatabaseHelper();
      await db.syncWithSupabase();
      _lastBackup = AutoBackupService.getLastBackupTimeString();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sauvegarde effectuée !'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏰ Sauvegarde automatique'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activation
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔄 Activation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sauvegarde automatique sur Supabase',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
                        Switch(
                          value: _isEnabled,
                          onChanged: _toggleBackup,
                          activeColor: AppTheme.primaryGold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Intervalle
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⏱️ Intervalle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toutes les $_interval heures',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildIntervalButton(1, '1h')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildIntervalButton(6, '6h')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildIntervalButton(12, '12h')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildIntervalButton(24, '24h')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dernière sauvegarde
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📅 Dernière sauvegarde',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastBackup,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _backupNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          '☁️ Sauvegarder maintenant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalButton(int hours, String label) {
    final isSelected = _interval == hours;
    return ElevatedButton(
      onPressed: () => _changeInterval(hours),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryGold : Colors.grey[700],
        foregroundColor: isSelected ? Colors.black : Colors.white,
        minimumSize: const Size(0, 40),
      ),
      child: Text(label),
    );
  }
}
