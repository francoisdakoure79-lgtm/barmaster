import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/product.dart';
import '../../../shared/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Sale> _sales = [];
  bool _isLoading = true;
  int? _selectedSaleId;

  @override
  void initState() {
    super.initState();
    _loadSales();
    _db.addListener(_refreshData);
  }

  @override
  void dispose() {
    _db.removeListener(_refreshData);
    super.dispose();
  }

  void _refreshData() {
    _loadSales();
  }

  void _loadSales() {
    setState(() => _isLoading = true);
    try {
      _sales = _db.getAllSales()
        ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    } catch (e) {
      print('❌ Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> _cancelSale(Sale sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Annuler la vente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous annuler la vente :'),
            const SizedBox(height: 8),
            Text(
              '${sale.ticketNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Montant: ${sale.totalAmount.toStringAsFixed(0)} FCFA',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Le stock sera rétabli automatiquement.',
              style: TextStyle(
                color: AppTheme.warningOrange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.dangerRed,
            ),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      final success = await _db.cancelSale(sale.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vente annulée avec succès'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadSales();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de l\'annulation'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

  List<SaleItem> _getSaleItems(int saleId) {
    return _db.getSaleItems(saleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Historique des ventes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune vente pour le moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Les ventes apparaîtront ici après les transactions',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _sales.length,
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    final isExpanded = _selectedSaleId == sale.id;
                    final items = _getSaleItems(sale.id);

                    return Card(
                      color: AppTheme.cardBackground,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _selectedSaleId = expanded ? sale.id : null;
                          });
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.receipt,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ),
                        title: Text(
                          sale.ticketNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(sale.saleDate),
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            Text(
                              '${sale.totalAmount.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                color: AppTheme.primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                sale.paymentMethod,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryGold,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.dangerRed,
                              ),
                              onPressed: () => _cancelSale(sale),
                              tooltip: 'Annuler la vente',
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text(
                                  'Détails du ticket',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...items.map((item) {
                                  final product = _db.getProductById(item.productId);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product?.name ?? 'Produit inconnu',
                                            style: TextStyle(color: Colors.grey[300]),
                                          ),
                                        ),
                                        Text(
                                          'x${item.quantity}',
                                          style: TextStyle(color: Colors.grey[400]),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '${item.totalPrice.toStringAsFixed(0)} FCFA',
                                          style: const TextStyle(
                                            color: AppTheme.primaryGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${sale.totalAmount.toStringAsFixed(0)} FCFA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('📄 Impression du ticket ${sale.ticketNumber}'),
                                              backgroundColor: AppTheme.primaryGold,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.print, size: 16),
                                        label: const Text('Imprimer'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primaryGold,
                                          side: BorderSide(color: AppTheme.primaryGold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('📄 PDF du ticket ${sale.ticketNumber}'),
                                              backgroundColor: AppTheme.primaryGold,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                                        label: const Text('PDF'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.primaryGold,
                                          side: BorderSide(color: AppTheme.primaryGold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
