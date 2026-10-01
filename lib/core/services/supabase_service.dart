import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: 'https://pznfzgmxqerbzfeykjta.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6bmZ6Z214cWVyYnpmZXlranRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzNDMwODcsImV4cCI6MjEwMDkxOTA4N30.m8WWYsPOj7T_t3sip-yoQLqa0XxBmVKRYATa1rc2cBQ',
    );
    _initialized = true;
  }

  static bool isInitialized() => _initialized;

  // ✅ INSCRIPTION
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String barName,
  }) async {
    try {
      // Utiliser l'API Admin pour créer l'utilisateur (service_role)
      final adminKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6bmZ6Z214cWVyYnpmZXlranRhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTM0MzA4NywiZXhwIjoyMTAwOTE5MDg3fQ.s8TWQoeJxzVp-UtlRyRqX67rXW3h9T33o25klUmfVVw';
      
      final http.Response response = await http.post(
        Uri.parse('https://pznfzgmxqerbzfeykjta.supabase.co/auth/v1/admin/users'),
        headers: {
          'apikey': adminKey,
          'Authorization': 'Bearer $adminKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'email_confirm': true,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': 'Compte créé'};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ✅ CONNEXION
  static Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // Utiliser l'API REST
      final http.Response response = await http.post(
        Uri.parse('https://pznfzgmxqerbzfeykjta.supabase.co/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6bmZ6Z214cWVyYnpmZXlranRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzNDMwODcsImV4cCI6MjEwMDkxOTA4N30.m8WWYsPOj7T_t3sip-yoQLqa0XxBmVKRYATa1rc2cBQ',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) return {'success': false, 'message': 'Identifiants incorrects'};

      String barName;
      if (email.contains('caissier_')) {
        barName = email.replaceAll('caissier_', '').replaceAll('@gmail.com', '').toUpperCase();
      } else if (email.contains('vendeuse_')) {
        barName = email.replaceAll('vendeuse_', '').replaceAll('@gmail.com', '').toUpperCase();
      } else {
        barName = email.replaceAll('@gmail.com', '').toUpperCase();
      }

      return {'success': true, 'barName': barName};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ✅ SAUVEGARDE
  static Future<void> saveData(String barId, Map<String, dynamic> data) async {
    try {
      await client.from('app_data').upsert({
        'id': barId,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ saveData: $e');
    }
  }

  // ✅ CHARGEMENT
  static Future<Map<String, dynamic>?> loadData(String barId) async {
    try {
      final response = await client.from('app_data').select('data').eq('id', barId).maybeSingle();
      if (response != null && response['data'] != null) {
        return jsonDecode(response['data']);
      }
      return null;
    } catch (e) {
      print('❌ loadData: $e');
      return null;
    }
  }

  static Future<List<String>> getAllBarIds() async {
    try {
      final response = await client.from('app_data').select('id');
      return (response as List).map((r) => r['id'].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearAll() async {
    try {
      await client.from('app_data').delete().neq('id', 'NONEXISTENT');
    } catch (e) {}
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
