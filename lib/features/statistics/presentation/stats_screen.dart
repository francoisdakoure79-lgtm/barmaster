import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/product.dart';
import '../../../shared/theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Product> _products = [];
  List<Sale> _sales = [];
  Map<int, int> _salesByProduct = {}; // productId -> quantité vendue
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _db.addListener(_refreshData);
  }

  @override
  void dispose() {
    _db.removeListener(_refreshData);
    super.dispose();
  }

  void _refreshData() => _loadData();

  void _loadData() {
    setState(() => _isLoading = true);
    _products = _db.getAllProducts();
    _sales = _db.getAllSales();
    _salesByProduct = {};
    for (var sale in _sales) {
      final items = _db.getSaleItems(sale.id);
      for (var item in items) {
        _salesByProduct[item.productId] = (_salesByProduct[item.productId] ?? 0) + item.quantity;
      }
    }
    setState(() => _isLoading = false);
  }

  double get _totalSales => _sales.fold(0.0, (sum, s) => sum + s.totalAmount);

  int get _totalItemsSold => _salesByProduct.values.fold(0, (sum, q) => sum + q);

  Product? get _bestSeller {
    if (_salesByProduct.isEmpty) return null;
    final best = _salesByProduct.entries.reduce((a, b) => a.value > b.value ? a : b);
    return _db.getProductById(best.key);
  }

  int get _bestSellerQty => _salesByProduct[_bestSeller?.id] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: _card('Total Ventes', '${_totalSales.toStringAsFixed(0)} FCFA', Icons.money, AppTheme.successGreen)),
                  const SizedBox(width: 12),
                  Expanded(child: _card('Articles vendus', '$_totalItemsSold', Icons.shopping_cart, Colors.blue)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _card('Nb Transactions', '${_sales.length}', Icons.receipt, AppTheme.primaryGold)),
                  const SizedBox(width: 12),
                  Expanded(child: _card('Nb Produits', '${_products.length}', Icons.inventory, Colors.purple)),
                ]),
                const SizedBox(height: 24),

                // Meilleur vendeur basé sur les VENTES
                const Text('🏆 Meilleure Vente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                if (_bestSeller != null)
                  Card(
                    color: AppTheme.cardBackground,
                    child: ListTile(
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Center(child: Icon(Icons.emoji_events, color: AppTheme.primaryGold)),
                      ),
                      title: Text(_bestSeller!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('Vendu $_bestSellerQty fois', style: TextStyle(color: Colors.grey[400])),
                      trailing: Text('${_bestSeller!.sellingPrice} FCFA', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  const Text('Aucune vente encore', style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 24),
                const Text('📋 Top Produits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ..._products.where((p) => _salesByProduct.containsKey(p.id)).take(5).map((p) => Card(
                  color: AppTheme.cardBackground,
                  child: ListTile(
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Vendu: ${_salesByProduct[p.id]} fois', style: TextStyle(color: Colors.grey[400])),
                    trailing: Text('${p.sellingPrice} FCFA', style: const TextStyle(color: AppTheme.primaryGold)),
                  ),
                )),
                if (_products.where((p) => _salesByProduct.containsKey(p.id)).isEmpty)
                  const Text('Aucune vente encore', style: TextStyle(color: Colors.grey)),
              ]),
            ),
    );
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[400]))]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}
