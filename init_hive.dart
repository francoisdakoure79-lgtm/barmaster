import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Copier les modèles
class Product {
  int id;
  String name;
  int categoryId;
  double purchasePrice;
  double sellingPrice;
  int minStockThreshold;
  int currentStock;
  String unit;
  String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.purchasePrice,
    required this.sellingPrice,
    this.minStockThreshold = 10,
    this.currentStock = 0,
    this.unit = 'unité',
    this.barcode,
  });
}

void main() async {
  print('🔄 Initialisation de la base de données Hive...');
  
  // Initialiser Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  final hiveDir = Directory('${appDocDir.path}/hive');
  if (!await hiveDir.exists()) {
    await hiveDir.create(recursive: true);
  }
  Hive.init(hiveDir.path);
  
  // Ouvrir la box (sans adaptateur, on va juste vérifier)
  var box = await Hive.openBox('products');
  
  print('📁 Dossier: ${hiveDir.path}');
  print('📦 Nombre de produits avant: ${box.length}');
  
  // Si vide, ajouter des données
  if (box.isEmpty) {
    print('📦 Ajout des produits de démonstration...');
    
    final products = [
      {'name': 'Heineken', 'categoryId': 1, 'purchasePrice': 600.0, 'sellingPrice': 1000.0, 'minStockThreshold': 10, 'currentStock': 25, 'unit': 'bouteille', 'barcode': '1234567890123'},
      {'name': 'Castel', 'categoryId': 1, 'purchasePrice': 450.0, 'sellingPrice': 800.0, 'minStockThreshold': 15, 'currentStock': 30, 'unit': 'bouteille', 'barcode': '1234567890124'},
      {'name': 'Coca-Cola', 'categoryId': 2, 'purchasePrice': 350.0, 'sellingPrice': 600.0, 'minStockThreshold': 20, 'currentStock': 5, 'unit': 'canette', 'barcode': '1234567890125'},
      {'name': 'Fanta Orange', 'categoryId': 2, 'purchasePrice': 350.0, 'sellingPrice': 600.0, 'minStockThreshold': 15, 'currentStock': 12, 'unit': 'canette', 'barcode': '1234567890126'},
      {'name': 'Whisky Johnnie Walker', 'categoryId': 3, 'purchasePrice': 5000.0, 'sellingPrice': 8500.0, 'minStockThreshold': 5, 'currentStock': 3, 'unit': 'bouteille', 'barcode': '1234567890127'},
    ];
    
    int id = 1;
    for (var data in products) {
      await box.put(id, data);
      print('  ✅ ${data['name']} ajouté');
      id++;
    }
    
    print('✅ ${products.length} produits ajoutés');
  }
  
  print('📦 Nombre de produits après: ${box.length}');
  
  // Afficher les produits
  print('\n📋 Liste des produits:');
  for (var key in box.keys) {
    var product = box.get(key);
    print('  - ${product['name']} (Stock: ${product['currentStock']})');
  }
  
  await box.close();
  print('✅ Base de données initialisée avec succès !');
  print('👉 Relancez l\'application avec: flutter run -d linux');
}
