import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

class NextcloudService {
  static final DatabaseHelper _db = DatabaseHelper();

  static String _serverUrl = '';
  static String _username = '';
  static String _password = '';
  static bool _isConnected = false;
  static Dio? _dio;

  // ============================================================
  // CONFIGURATION
  // ============================================================

  static void setConfig(String url, String username, String password) {
    _serverUrl = url.trim();
    _username = username.trim();
    _password = password.trim();
    
    _dio = Dio(BaseOptions(
      baseUrl: _serverUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    // Ajouter l'authentification Basic
    final credentials = '$_username:$_password';
    final encoded = base64Encode(utf8.encode(credentials));
    _dio!.options.headers['Authorization'] = 'Basic $encoded';
    
    _isConnected = false;
  }

  static bool isConfigured() {
    return _serverUrl.isNotEmpty && _username.isNotEmpty && _password.isNotEmpty;
  }

  // ============================================================
  // CONNEXION
  // ============================================================

  static Future<bool> testConnection() async {
    if (!isConfigured() || _dio == null) return false;

    try {
      final response = await _dio!.get('/remote.php/dav/files/$_username/');
      _isConnected = response.statusCode == 200 || response.statusCode == 207;
      return _isConnected;
    } catch (e) {
      print('❌ Erreur connexion Nextcloud: $e');
      _isConnected = false;
      return false;
    }
  }

  static bool isConnected() {
    return _isConnected;
  }

  // ============================================================
  // SAUVEGARDE
  // ============================================================

  static Future<bool> backupDatabase() async {
    if (!isConnected() || _dio == null) {
      print('❌ Nextcloud non connecté');
      return false;
    }

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dataFile = File('${appDocDir.path}/barmaster_data/data.json');
      
      if (!await dataFile.exists()) {
        print('❌ Fichier de données introuvable');
        return false;
      }

      final content = await dataFile.readAsString();
      
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'barmaster_backup_$dateStr.json';

      // Créer le dossier s'il n'existe pas
      await _createDirectory('/BarMaster_Backups');
      
      final url = '/remote.php/dav/files/$_username/BarMaster_Backups/$fileName';
      final response = await _dio!.put(
        url,
        data: content,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 204) {
        print('✅ Sauvegarde Nextcloud: $fileName');
        return true;
      } else {
        print('❌ Erreur sauvegarde: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      return false;
    }
  }

  // ============================================================
  // RESTAURATION
  // ============================================================

  static Future<List<String>> listBackups() async {
    if (!isConnected() || _dio == null) return [];

    try {
      final url = '/remote.php/dav/files/$_username/BarMaster_Backups/';
      final response = await _dio!.request(
        url,
        options: Options(
          method: 'PROPFIND',
          headers: {
            'Depth': '1',
            'Content-Type': 'application/xml',
          },
        ),
      );

      if (response.statusCode == 207) {
        final body = response.data as String;
        final regex = RegExp(r'<d:href>(.*?)</d:href>');
        final matches = regex.allMatches(body);
        final List<String> files = [];
        for (var match in matches) {
          final href = match.group(1) ?? '';
          final name = href.split('/').last;
          if (name.startsWith('barmaster_backup_') && name.endsWith('.json')) {
            files.add(name);
          }
        }
        return files;
      }
      return [];
    } catch (e) {
      print('❌ Erreur liste sauvegardes: $e');
      return [];
    }
  }

  static Future<bool> restoreBackup(String fileName) async {
    if (!isConnected() || _dio == null) {
      print('❌ Nextcloud non connecté');
      return false;
    }

    try {
      final url = '/remote.php/dav/files/$_username/BarMaster_Backups/$fileName';
      final response = await _dio!.get(url);

      if (response.statusCode == 200) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final dataFile = File('${appDocDir.path}/barmaster_data/data.json');
        
        // Sauvegarder l'ancien fichier
        if (await dataFile.exists()) {
          final backupName = 'data_backup_${DateTime.now().millisecondsSinceEpoch}.json';
          await dataFile.copy('${appDocDir.path}/barmaster_data/$backupName');
          print('📁 Ancienne base sauvegardée: $backupName');
        }

        await dataFile.writeAsString(response.data as String);
        print('✅ Restauration réussie: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur restauration: $e');
      return false;
    }
  }

  // ============================================================
  // EXPORT DES RAPPORTS
  // ============================================================

  static Future<bool> exportReport(String content, String fileName) async {
    if (!isConnected() || _dio == null) {
      print('❌ Nextcloud non connecté');
      return false;
    }

    try {
      await _createDirectory('/BarMaster_Rapports');
      
      final url = '/remote.php/dav/files/$_username/BarMaster_Rapports/$fileName';
      final response = await _dio!.put(
        url,
        data: content,
        options: Options(
          headers: {'Content-Type': 'text/plain'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 204) {
        print('✅ Rapport exporté: $fileName');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Erreur export rapport: $e');
      return false;
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  static Future<void> _createDirectory(String path) async {
    try {
      final url = '/remote.php/dav/files/$_username/$path';
      await _dio!.request(
        url,
        options: Options(method: 'MKCOL'),
      );
    } catch (e) {
      // Le dossier existe peut-être déjà
    }
  }

  static void disconnect() {
    _isConnected = false;
    _dio = null;
  }

  static Map<String, String> getConfig() {
    return {
      'url': _serverUrl,
      'username': _username,
      'password': _password,
    };
  }
}
