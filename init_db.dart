import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  print('🔄 Initialisation de la base de données...');
  
  String path = join(await getDatabasesPath(), 'barmaster.db');
  print('📁 Chemin: $path');
  
  // Supprimer l'ancienne base
  await deleteDatabase(path);
  print('🗑️ Ancienne base supprimée');
  
  // Ouvrir la base (va la créer avec les données)
  Database db = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      print('📦 Création des tables...');
      
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          purchase_price REAL NOT NULL,
          selling_price REAL NOT NULL,
          min_stock_threshold INTEGER DEFAULT 10,
          current_stock INTEGER DEFAULT 0,
          unit TEXT DEFAULT 'unité',
          barcode TEXT,
          is_active INTEGER DEFAULT 1
        )
      ''');
      
      await db.execute('''
        CREATE TABLE sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ticket_number TEXT NOT NULL,
          total_amount REAL NOT NULL,
          sale_date INTEGER NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          total_price REAL NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
      
      print('✅ Tables créées');
      
      // Produits de démonstration
      print('📦 Ajout des produits...');
      await db.insert('products', {
        'name': 'Heineken',
        'category_id': 1,
        'purchase_price': 600,
        'selling_price': 1000,
        'min_stock_threshold': 10,
        'current_stock': 25,
        'unit': 'bouteille',
        'barcode': '1234567890123',
      });
      await db.insert('products', {
        'name': 'Castel',
        'category_id': 1,
        'purchase_price': 450,
        'selling_price': 800,
        'min_stock_threshold': 15,
        'current_stock': 30,
        'unit': 'bouteille',
        'barcode': '1234567890124',
      });
      await db.insert('products', {
        'name': 'Coca-Cola',
        'category_id': 2,
        'purchase_price': 350,
        'selling_price': 600,
        'min_stock_threshold': 20,
        'current_stock': 5,
        'unit': 'canette',
        'barcode': '1234567890125',
      });
      await db.insert('products', {
        'name': 'Fanta Orange',
        'category_id': 2,
        'purchase_price': 350,
        'selling_price': 600,
        'min_stock_threshold': 15,
        'current_stock': 12,
        'unit': 'canette',
        'barcode': '1234567890126',
      });
      await db.insert('products', {
        'name': 'Whisky Johnnie Walker',
        'category_id': 3,
        'purchase_price': 5000,
        'selling_price': 8500,
        'min_stock_threshold': 5,
        'current_stock': 3,
        'unit': 'bouteille',
        'barcode': '1234567890127',
      });
      
      print('✅ 5 produits ajoutés');
    },
  );
  
  // Vérification
  List<Map<String, dynamic>> products = await db.query('products');
  print('📦 Nombre de produits: ${products.length}');
  for (var p in products) {
    print('  - ${p['name']} (Stock: ${p['current_stock']})');
  }
  
  await db.close();
  print('✅ Base de données initialisée avec succès !');
  print('👉 Relancez l\'application avec: flutter run -d linux');
}
