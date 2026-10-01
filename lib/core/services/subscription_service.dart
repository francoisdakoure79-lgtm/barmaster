import 'supabase_service.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static DateTime? _subscriptionEnd;
  static String _currentBarName = '';

  // Générer une clé
  static Future<String> generateKey({int durationDays = 30}) async {
    final random = Random();
    final key = List.generate(12, (_) => random.nextInt(10)).join();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('generated_sub_key', key);
    await prefs.setInt('generated_sub_duration', durationDays);
    return key;
  }

  // Activer pour un bar spécifique
  static Future<String> activateSubscription(String key, {required String barName}) async {
    if (key.length != 12 || int.tryParse(key) == null) return '❌ Cle invalide';
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('generated_sub_key') ?? '';
    if (savedKey.isEmpty) return '❌ Aucune cle generee';
    if (key != savedKey) return '❌ Cle non reconnue';

    final duration = prefs.getInt('generated_sub_duration') ?? 30;
    final now = DateTime.now();
    final end = now.add(Duration(days: duration));

    // ✅ Sauvegarder PAR BAR (local + Supabase)
    await prefs.setString('subscription_end_$barName', end.toIso8601String());
    await prefs.setString('generated_sub_key', '');
    try {
      await SupabaseService.saveData('sub_$barName', {'end': end.toIso8601String(), 'barName': barName});
      print('✅ Abonnement sauvegardé dans Supabase');
    } catch (e) {}

    _subscriptionEnd = end;
    _currentBarName = barName;
    return '✅ Active jusqu au ${end.day}/${end.month}/${end.year}';
  }

  // ✅ Vérifier pour un bar spécifique
  static bool isSubscriptionActive(String barName) {
    if (_subscriptionEnd == null) return false;
    return DateTime.now().isBefore(_subscriptionEnd!);
  }

  // Charger l'expiration pour le bar connecté
  static Future<void> loadForBar(String barName) async {
    // Charger depuis Supabase
    try {
      final data = await SupabaseService.loadData('sub_$barName');
      if (data != null && data['end'] != null) {
        _subscriptionEnd = DateTime.parse(data['end']);
        _currentBarName = barName;
        print('✅ Abonnement chargé depuis Supabase');
        return;
      }
    } catch (e) {}
    
    // Fallback local
    final prefs = await SharedPreferences.getInstance();
    final endStr = prefs.getString('subscription_end_$barName');
    if (endStr != null) {
      _subscriptionEnd = DateTime.parse(endStr);
      _currentBarName = barName;
    } else {
      _subscriptionEnd = null;
      _currentBarName = '';
    }
  }

  static bool isExpired() {
    if (_subscriptionEnd == null) return false;
    return DateTime.now().isAfter(_subscriptionEnd!);
  }

  static String getRemainingDays() {
    if (_subscriptionEnd == null) return 'Aucun';
    if (DateTime.now().isAfter(_subscriptionEnd!)) return 'Expire';
    final days = _subscriptionEnd!.difference(DateTime.now()).inDays;
    if (days <= 5) return '⚠️ $days jour${days > 1 ? 's' : ''} !';
    return '$days jour${days > 1 ? 's' : ''}';
  }
}
