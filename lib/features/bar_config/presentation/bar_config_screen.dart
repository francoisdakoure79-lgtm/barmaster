import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/bar_config.dart';
import '../../../shared/theme/app_theme.dart';

class BarConfigScreen extends StatefulWidget {
  const BarConfigScreen({super.key});

  @override
  State<BarConfigScreen> createState() => _BarConfigScreenState();
}

class _BarConfigScreenState extends State<BarConfigScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  late BarConfig _config;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    setState(() => _isLoading = true);
    try {
      _config = _db.getBarConfig();
      _nameController.text = _config.name;
      _addressController.text = _config.address;
      _phoneController.text = _config.phone;
      _emailController.text = _config.email;
      _sloganController.text = _config.slogan;
      _currencyController.text = _config.currency;
    } catch (e) {
      print('❌ Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  void _saveConfig() {
    final config = BarConfig()
      ..name = _nameController.text.trim()
      ..address = _addressController.text.trim()
      ..phone = _phoneController.text.trim()
      ..email = _emailController.text.trim()
      ..slogan = _sloganController.text.trim()
      ..currency = _currencyController.text.trim().isEmpty ? 'FCFA' : _currencyController.text.trim();

    _db.saveBarConfig(config);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Configuration sauvegardée !'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
    
    _loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasContent = _nameController.text.isNotEmpty ||
        _addressController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _emailController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 Configuration du bar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Aperçu
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            '📋 Aperçu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _nameController.text.isEmpty ? 'Mon Bar' : _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _sloganController.text.isEmpty ? 'Le meilleur du terroir' : _sloganController.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_addressController.text.isNotEmpty)
                                  Text(
                                    _addressController.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                if (_phoneController.text.isNotEmpty)
                                  Text(
                                    _phoneController.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                if (_emailController.text.isNotEmpty)
                                  Text(
                                    _emailController.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                if (!hasContent)
                                  Text(
                                    'Aucune information configurée',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Formulaire
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✏️ Informations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nom
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: '🏪 Nom du bar / maquis',
                              hintText: 'Ex: BarMaster',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.store),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Slogan
                          TextField(
                            controller: _sloganController,
                            decoration: const InputDecoration(
                              labelText: '📝 Slogan',
                              hintText: 'Ex: Le meilleur du terroir',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.format_quote),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Adresse
                          TextField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: '📍 Adresse',
                              hintText: 'Ex: Abidjan, Cocody',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Téléphone
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: '📞 Téléphone',
                              hintText: 'Ex: +225 07 07 07 07',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: '📧 Email',
                              hintText: 'Ex: contact@monbar.com',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Devise
                          TextField(
                            controller: _currencyController,
                            decoration: const InputDecoration(
                              labelText: '💰 Devise',
                              hintText: 'Ex: FCFA, CFA, Euro',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.money),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveConfig,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text(
                                '💾 Sauvegarder la configuration',
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
                  ),

                  const SizedBox(height: 16),

                  // Info
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💡 Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cette configuration s\'affichera sur :',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Les tickets de caisse',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                          Text(
                            '• Les rapports PDF',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                          Text(
                            '• Les en-têtes de documents',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
}
