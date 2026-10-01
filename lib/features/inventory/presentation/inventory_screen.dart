import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/product.dart';
import '../../../shared/theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _db.addListener(_refreshData);
  }

  @override
  void dispose() {
    _db.removeListener(_refreshData);
    super.dispose();
  }

  void _refreshData() {
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _products = _db.getAllProducts();
    });
  }

  void _updateStock(Product product, int delta) {
    final newStock = product.currentStock + delta;
    if (newStock < 0) return;

    try {
      _db.updateProductStock(product.id, newStock);
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _editProduct(Product product) {
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController purchasePriceController = TextEditingController(
      text: product.purchasePrice.toString(),
    );
    final TextEditingController sellingPriceController = TextEditingController(
      text: product.sellingPrice.toString(),
    );
    final TextEditingController thresholdController = TextEditingController(
      text: product.minStockThreshold.toString(),
    );
    int selectedCategory = product.categoryId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ Modifier le produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purchasePriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Prix d'achat (FCFA)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sellingPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix de vente (FCFA)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Seuil d'alerte",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('🍺 Bières')),
                  DropdownMenuItem(value: 2, child: Text('🥤 Sodas')),
                  DropdownMenuItem(value: 3, child: Text('🥃 Spiritueux')),
                ],
                onChanged: (value) {
                  selectedCategory = value ?? 1;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newPurchasePrice = double.tryParse(purchasePriceController.text);
              final newSellingPrice = double.tryParse(sellingPriceController.text);
              final newThreshold = int.tryParse(thresholdController.text);

              if (newName.isEmpty || newPurchasePrice == null || newSellingPrice == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs'),
                    backgroundColor: AppTheme.warningOrange,
                  ),
                );
                return;
              }

              // Mettre à jour le produit
              product.name = newName;
              product.purchasePrice = newPurchasePrice;
              product.sellingPrice = newSellingPrice;
              product.minStockThreshold = newThreshold ?? 10;
              product.categoryId = selectedCategory;

              _db.updateProductStock(product.id, product.currentStock); // Force save
              _loadProducts();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${product.name} modifié !'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: AppTheme.primaryGold),
                  SizedBox(height: 16),
                  Text(
                    'Aucun produit dans l\'inventaire',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ajoutez des produits via l\'onglet ACHAT',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                Color cardColor = AppTheme.cardBackground;
                if (product.isCritical) {
                  cardColor = AppTheme.dangerRed.withOpacity(0.2);
                } else if (product.isWarning) {
                  cardColor = AppTheme.warningOrange.withOpacity(0.2);
                }

                return Card(
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              product.currentStock.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Achat: ${product.purchasePrice.toStringAsFixed(0)} FCFA | Vente: ${product.sellingPrice.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  color: AppTheme.primaryGold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Stock: ${product.currentStock} / Seuil: ${product.minStockThreshold}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: product.isCritical
                                      ? AppTheme.dangerRed
                                      : product.isWarning
                                          ? AppTheme.warningOrange
                                          : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Bouton Modifier (✏️)
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.primaryGold),
                              onPressed: () => _editProduct(product),
                            ),
                            // Boutons +/- stock
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  color: AppTheme.dangerRed),
                              onPressed: () => _updateStock(product, -1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add,
                                  color: AppTheme.successGreen),
                              onPressed: () => _updateStock(product, 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
