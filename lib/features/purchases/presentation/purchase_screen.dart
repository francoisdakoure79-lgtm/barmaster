import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/product.dart';
import '../../../shared/theme/app_theme.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});
  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  int _selectedCategory = 1;
  String _message = '';
  Color _messageColor = AppTheme.successGreen;

  // ✅ Stocker le dernier achat pour annulation
  Map<String, dynamic>? _lastPurchase;
  bool _canUndo = false;

  @override
  void initState() {
    super.initState();
    _db.addListener(_refreshData);
  }

  @override
  void dispose() {
    _db.removeListener(_refreshData);
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (mounted) setState(() {});
  }

  void _addStock() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final quantityText = _quantityController.text.trim();
    final thresholdText = _thresholdController.text.trim();

    if (name.isEmpty || priceText.isEmpty || quantityText.isEmpty) {
      setState(() { _message = '⚠️ Remplissez tous les champs'; _messageColor = AppTheme.warningOrange; });
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() { _message = '⚠️ Prix invalide'; _messageColor = AppTheme.dangerRed; });
      return;
    }

    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      setState(() { _message = '⚠️ Quantité invalide'; _messageColor = AppTheme.dangerRed; });
      return;
    }

    // ✅ Sauvegarder l'état avant modification pour annulation
    final existingProduct = _db.getProductByName(name);
    _lastPurchase = {
      'name': name,
      'quantity': quantity,
      'previousStock': existingProduct?.currentStock ?? 0,
      'productId': existingProduct?.id,
    };

    try {
      _db.addStockToProduct(name, quantity, price, _selectedCategory);
      setState(() {
        _message = '✅ $quantity $name ajouté(s) au stock';
        _messageColor = AppTheme.successGreen;
        _canUndo = true;
      });
      _nameController.clear();
      _priceController.clear();
      _quantityController.clear();
    } catch (e) {
      setState(() { _message = '❌ Erreur: $e'; _messageColor = AppTheme.dangerRed; });
    }
  }

  // ✅ Annuler le dernier achat
  void _undoLastPurchase() {
    if (_lastPurchase == null) return;

    final product = _db.getProductByName(_lastPurchase!['name']);
    if (product != null) {
      final newStock = product.currentStock - (_lastPurchase!['quantity'] as int);
      _db.updateProductStock(product.id, newStock < 0 ? 0 : newStock);
    }

    setState(() {
      _message = '↩️ Achat annulé : ${_lastPurchase!['name']}';
      _messageColor = AppTheme.warningOrange;
      _canUndo = false;
      _lastPurchase = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _db.getAllProducts();
    final categories = _db.getAllCategories();

    return Scaffold(
      appBar: AppBar(title: const Text('Approvisionnement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Message + bouton Annuler
          if (_message.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: _messageColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(_messageColor == AppTheme.successGreen ? Icons.check_circle : Icons.warning, color: _messageColor),
                const SizedBox(width: 12),
                Expanded(child: Text(_message, style: TextStyle(color: _messageColor))),
                // ✅ BOUTON ANNULER
                if (_canUndo)
                  TextButton.icon(
                    onPressed: _undoLastPurchase,
                    icon: const Icon(Icons.undo, color: AppTheme.warningOrange),
                    label: const Text('ANNULER', style: TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold)),
                  ),
              ]),
            ),

          // Catégorie
          if (categories.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          const SizedBox(height: 12),

          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nom du produit'), style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Prix d\'achat'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantité'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 12),
          TextField(controller: _thresholdController, decoration: const InputDecoration(labelText: 'Stock minimum (optionnel)'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _addStock,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black, padding: const EdgeInsets.all(14)),
            child: const Text('AJOUTER AU STOCK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}
