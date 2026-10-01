import 'package:flutter/material.dart';
import '../../../core/services/nextcloud_service.dart';
import '../../../shared/theme/app_theme.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isConfigured = false;
  bool _isConnected = false;
  bool _isLoading = false;
  String _status = '';
  Color _statusColor = Colors.grey;
  
  List<String> _backups = [];
  bool _isLoadingBackups = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    final config = NextcloudService.getConfig();
    if (config['url']!.isNotEmpty) {
      _urlController.text = config['url']!;
      _usernameController.text = config['username']!;
      _passwordController.text = config['password']!;
      _isConfigured = true;
      _checkConnection();
    }
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Test de connexion...';
      _statusColor = Colors.orange;
    });

    try {
      final connected = await NextcloudService.testConnection();
      setState(() {
        _isConnected = connected;
        _isLoading = false;
        _status = connected ? '✅ Connecté à Nextcloud' : '❌ Connexion échouée';
        _statusColor = connected ? AppTheme.successGreen : AppTheme.dangerRed;
      });
      if (connected) {
        await _loadBackups();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Erreur: $e';
        _statusColor = AppTheme.dangerRed;
      });
    }
  }

  Future<void> _saveConfig() async {
    final url = _urlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _status = '⚠️ Veuillez remplir tous les champs';
        _statusColor = AppTheme.warningOrange;
      });
      return;
    }

    NextcloudService.setConfig(url, username, password);
    _isConfigured = true;
    await _checkConnection();
  }

  Future<void> _loadBackups() async {
    setState(() {
      _isLoadingBackups = true;
    });
    _backups = await NextcloudService.listBackups();
    setState(() {
      _isLoadingBackups = false;
    });
  }

  Future<void> _backupNow() async {
    setState(() {
      _isLoading = true;
      _status = 'Sauvegarde en cours...';
      _statusColor = Colors.orange;
    });

    final success = await NextcloudService.backupDatabase();
    
    setState(() {
      _isLoading = false;
      _status = success ? '✅ Sauvegarde réussie !' : '❌ Sauvegarde échouée';
      _statusColor = success ? AppTheme.successGreen : AppTheme.dangerRed;
    });
    
    if (success) {
      await _loadBackups();
    }
  }

  Future<void> _restoreBackup(String fileName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Restaurer une sauvegarde'),
        content: Text(
          'Voulez-vous restaurer $fileName ?\n\n'
          '⚠️ Cela remplacera toutes les données locales actuelles !'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Restauration en cours...';
      _statusColor = Colors.orange;
    });

    final success = await NextcloudService.restoreBackup(fileName);
    
    setState(() {
      _isLoading = false;
      _status = success ? '✅ Restauration réussie !' : '❌ Restauration échouée';
      _statusColor = success ? AppTheme.successGreen : AppTheme.dangerRed;
    });
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Redémarrez l\'application pour appliquer les changements'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synchronisation Nextcloud'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: _statusColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _status.isEmpty ? 'Configuration requise' : _status,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_isConnected) ...[
                      const SizedBox(height: 8),
                      Text(
                        '📁 Dossiers: BarMaster_Backups, BarMaster_Rapports',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Configuration
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔗 Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'URL Nextcloud',
                        hintText: 'https://nextcloud.example.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveConfig,
                            icon: const Icon(Icons.save),
                            label: const Text('Sauvegarder et tester'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            if (_isConnected) ...[
              Card(
                color: AppTheme.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📦 Sauvegarde',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _backupNow,
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Sauvegarder maintenant'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      const Text(
                        '📋 Sauvegardes disponibles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_isLoadingBackups)
                        const Center(child: CircularProgressIndicator())
                      else if (_backups.isEmpty)
                        Text(
                          'Aucune sauvegarde disponible',
                          style: TextStyle(color: Colors.grey[400]),
                        )
                      else
                        ..._backups.map((backup) {
                          return Card(
                            color: Colors.grey[800],
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.cloud_download, color: AppTheme.primaryGold),
                              title: Text(
                                backup,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.restore, color: AppTheme.primaryGold),
                                onPressed: () => _restoreBackup(backup),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
