import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/product.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../main.dart';
import '../../settings/presentation/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic> _stats = {};
  List<Product> _lowStock = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _db.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _db.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _loadData();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    try {
      _stats = _db.getTodayStats();
      _lowStock = _db.getLowStockProducts();
      print('📊 Ventes du jour: ${_stats['totalSalesToday']} FCFA');
    } catch (e) {
      print('❌ Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BarMaster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          return Future.value();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Ventes du jour',
                            '${_stats['totalSalesToday']?.toStringAsFixed(0) ?? 0} FCFA',
                            Icons.today,
                            AppTheme.successGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Ruptures',
                            '${_stats['criticalCount'] ?? 0}',
                            Icons.cancel,
                            AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Alertes',
                            '${_stats['warningCount'] ?? 0}',
                            Icons.warning_amber_rounded,
                            AppTheme.warningOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Valeur Stock',
                            '${_stats['totalStockValue']?.toStringAsFixed(0) ?? 0}',
                            Icons.inventory,
                            AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Actions Rapides',
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
                          child: _buildActionButton(
                            'Vente',
                            Icons.shopping_cart,
                            AppTheme.primaryGold,
                            () => _navigateTo(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Stock',
                            Icons.inventory,
                            Colors.blueGrey,
                            () => _navigateTo(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Achat',
                            Icons.add_shopping_cart,
                            Colors.green,
                            () => _navigateTo(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Stats',
                            Icons.bar_chart,
                            Colors.purple,
                            () => _navigateTo(4),
                          ),
                        ),
                      ],
                    ),

                    if (_lowStock.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        '⚠️ Alertes Stock',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._lowStock.take(3).map((product) {
                        final isCritical = product.isCritical;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isCritical
                              ? AppTheme.dangerRed.withOpacity(0.2)
                              : AppTheme.warningOrange.withOpacity(0.2),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              isCritical ? Icons.cancel : Icons.warning_amber_rounded,
                              color: isCritical ? AppTheme.dangerRed : AppTheme.warningOrange,
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'Stock: ${product.currentStock} / Seuil: ${product.minStockThreshold}',
                              style: TextStyle(
                                color: isCritical ? AppTheme.dangerRed : AppTheme.warningOrange,
                              ),
                            ),
                            trailing: isCritical
                                ? const Text(
                                    'RUPTURE',
                                    style: TextStyle(
                                      color: AppTheme.dangerRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Text(
                                    'BAS',
                                    style: TextStyle(
                                      color: AppTheme.warningOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      }),
                      if (_lowStock.length > 3)
                        TextButton(
                          onPressed: () => _navigateTo(2),
                          child: Text('Voir tous (${_lowStock.length})'),
                        ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(int index) {
    final mainScreen = context.findAncestorStateOfType<MainScreenState>();
    if (mainScreen != null) {
      mainScreen.navigateTo(index);
    }
  }
}
