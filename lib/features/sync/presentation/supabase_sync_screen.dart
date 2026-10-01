import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import "package:barmaster/core/services/auth_service.dart";
import '../../../core/database/database_helper.dart';
import '../../../shared/theme/app_theme.dart';

class SupabaseSyncScreen extends StatefulWidget {
  const SupabaseSyncScreen({super.key});

  @override
  State<SupabaseSyncScreen> createState() => _SupabaseSyncScreenState();
}

class _SupabaseSyncScreenState extends State<SupabaseSyncScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isSyncing = false;
  String _status = 'Prêt';
  Color _statusColor = Colors.grey;
  String _barId = '';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _status = 'Vérification de la connexion...';
      _statusColor = Colors.orange;
    });

    try {
      final config = _db.getBarConfig();
      _barId = config.name.isNotEmpty 
          ? config.name.toLowerCase().replaceAll(' ', '_') 
          : 'mon_bar';
      
      final user = AuthService.getCurrentUser();
      setState(() {
        _status = user != null 
            ? '✅ Connecté à Supabase (Bar: $_barId)' 
            : '⚠️ Non connecté à Supabase';
        _statusColor = user != null ? AppTheme.successGreen : AppTheme.warningOrange;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erreur: $e';
        _statusColor = AppTheme.dangerRed;
      });
    }
  }

  Future<void> _syncToSupabase() async {
    setState(() {
      _isSyncing = true;
      _status = '🔄 Sauvegarde en cours...';
      _statusColor = Colors.orange;
    });

    try {
      await _db.saveAndSync();
      setState(() {
        _status = '✅ Sauvegarde réussie !';
        _statusColor = AppTheme.successGreen;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Données sauvegardées (local + Supabase)'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      setState(() {
        _status = '❌ Erreur: $e';
        _statusColor = AppTheme.dangerRed;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }

    setState(() {
      _isSyncing = false;
    });
  }

  Future<void> _loadFromSupabase() async {
    setState(() {
      _isSyncing = true;
      _status = '🔄 Chargement depuis Supabase...';
      _statusColor = Colors.orange;
    });

    try {
      await _db.loadFromSupabase();
      setState(() {
        _status = '✅ Données chargées depuis Supabase !';
        _statusColor = AppTheme.successGreen;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Données chargées depuis Supabase'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      setState(() {
        _status = '❌ Erreur: $e';
        _statusColor = AppTheme.dangerRed;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }

    setState(() {
      _isSyncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Synchronisation Supabase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnection,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('✅') ? Icons.check_circle : 
                      _status.contains('❌') ? Icons.error :
                      _status.contains('⚠️') ? Icons.warning_amber_rounded :
                      Icons.sync,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏪 Informations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID du bar: $_barId',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      'URL Supabase: pznfzgmxqerbzfeykjta.supabase.co',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Données synchronisées',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Produits', style: TextStyle(color: Colors.grey)),
                    const Text('✅ Ventes', style: TextStyle(color: Colors.grey)),
                    const Text('✅ Utilisateurs', style: TextStyle(color: Colors.grey)),
                    const Text('✅ Catégories', style: TextStyle(color: Colors.grey)),
                    const Text('✅ Configuration du bar', style: TextStyle(color: Colors.grey)),
                    const Text('✅ Abonnements', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSyncing ? null : _syncToSupabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                ),
                child: _isSyncing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        '☁️ Sauvegarder sur Supabase',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isSyncing ? null : _loadFromSupabase,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGold,
                  side: BorderSide(color: AppTheme.primaryGold),
                ),
                child: const Text(
                  '📥 Charger depuis Supabase',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
