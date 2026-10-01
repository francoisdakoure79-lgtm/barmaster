import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔄 Initialisation complète de la base de données...');
  
  final homeDir = Platform.environment['HOME'] ?? '/home/franck';
  final hiveDir = Directory('$homeDir/.local/share/hive');
  
  if (!await hiveDir.exists()) {
    await hiveDir.create(recursive: true);
    print('📁 Dossier créé: ${hiveDir.path}');
  }
  
  final dataFile = File('${hiveDir.path}/products.json');
  
  // Données de démonstration complètes
  final products = [
    {'id': 1, 'name': 'Heineken', 'categoryId': 1, 'purchasePrice': 600.0, 'sellingPrice': 1000.0, 'minStockThreshold': 10, 'currentStock': 25, 'unit': 'bouteille', 'barcode': '1234567890123'},
    {'id': 2, 'name': 'Castel', 'categoryId': 1, 'purchasePrice': 450.0, 'sellingPrice': 800.0, 'minStockThreshold': 15, 'currentStock': 30, 'unit': 'bouteille', 'barcode': '1234567890124'},
    {'id': 3, 'name': 'Coca-Cola', 'categoryId': 2, 'purchasePrice': 350.0, 'sellingPrice': 600.0, 'minStockThreshold': 20, 'currentStock': 5, 'unit': 'canette', 'barcode': '1234567890125'},
    {'id': 4, 'name': 'Fanta Orange', 'categoryId': 2, 'purchasePrice': 350.0, 'sellingPrice': 600.0, 'minStockThreshold': 15, 'currentStock': 12, 'unit': 'canette', 'barcode': '1234567890126'},
    {'id': 5, 'name': 'Whisky Johnnie Walker', 'categoryId': 3, 'purchasePrice': 5000.0, 'sellingPrice': 8500.0, 'minStockThreshold': 5, 'currentStock': 3, 'unit': 'bouteille', 'barcode': '1234567890127'},
  ];
  
  await dataFile.writeAsString(jsonEncode(products));
  print('✅ ${products.length} produits sauvegardés');
  
  print('\n📋 Liste des produits:');
  for (var product in products) {
    print('  - ${product['name']} (Stock: ${product['currentStock']} - ${product['sellingPrice']} FCFA)');
  }
  
  print('\n✅ Base de données initialisée avec succès !');
  print('👉 Relancez l\'application avec: flutter run -d linux');
}
