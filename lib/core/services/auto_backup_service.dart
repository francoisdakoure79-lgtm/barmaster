import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'supabase_service.dart';

class AutoBackupService {
  static final DatabaseHelper _db = DatabaseHelper();
  static Timer? _timer;
  static bool _isEnabled = false;
  static int _intervalHours = 6;

  static Future<void> startAutoBackup() async {
    if (_isEnabled) return;
    
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('auto_backup_enabled') ?? true;
    
    if (!enabled) {
      print('⚠️ Sauvegarde automatique désactivée');
      return;
    }
    
    _isEnabled = true;
    _intervalHours = prefs.getInt('auto_backup_interval') ?? 6;
    
    _timer = Timer.periodic(Duration(hours: _intervalHours), (timer) async {
      await _performBackup();
    });
    
    print('✅ Sauvegarde automatique activée (toutes les $_intervalHours heures)');
    
    Future.delayed(const Duration(minutes: 1), () {
      _performBackup();
    });
  }

  static void stopAutoBackup() {
    _timer?.cancel();
    _timer = null;
    _isEnabled = false;
    print('❌ Sauvegarde automatique désactivée');
  }

  static Future<void> _performBackup() async {
    try {
      if (!SupabaseService.isInitialized()) {
        print('⚠️ Supabase non initialisé');
        return;
      }

      // Récupérer les données avec les bons types
      await _db.syncWithSupabase();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_auto_backup', DateTime.now().millisecondsSinceEpoch);
      
      print('✅ Sauvegarde automatique effectuée à ${DateTime.now()}');
    } catch (e) {
      print('❌ Erreur sauvegarde automatique: $e');
      // Ne pas arrêter le timer en cas d'erreur
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', enabled);
    
    if (enabled) {
      _isEnabled = true;
      startAutoBackup();
    } else {
      stopAutoBackup();
    }
    print('🔄 Sauvegarde automatique: ${enabled ? "activée" : "désactivée"}');
  }

  static Future<void> setInterval(int hours) async {
    if (hours < 1) hours = 1;
    _intervalHours = hours;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_backup_interval', hours);
    
    if (_isEnabled) {
      stopAutoBackup();
      startAutoBackup();
    }
    print('⏱️ Intervalle sauvegarde: $hours heures');
  }

  static bool isEnabled() {
    return _isEnabled;
  }

  static int getInterval() {
    return _intervalHours;
  }

  static Future<int> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('last_auto_backup') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static String getLastBackupTimeString() {
    final timestamp = getLastBackupTime();
    if (timestamp == 0) return 'Jamais';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
