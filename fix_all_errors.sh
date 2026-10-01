#!/bin/bash
echo "🔧 Correction des erreurs BARMASTER..."

cd ~/Documents/barmaster

# 1. Backups
cp lib/core/database/database_helper.dart lib/core/database/database_helper.dart.bak_$(date +%Y%m%d_%H%M%S)

# 2. Corriger les imports Category
echo "Correction des imports Category..."
sed -i 's/import '\''models\/category.dart'\'';/import '\''models\/category.dart'\'' as cat_model;/' lib/core/database/database_helper.dart

# 3. Ajouter les méthodes manquantes (si pas déjà présentes)
echo "Ajout des méthodes manquantes..."

# Vérifier et ajouter loadFromSupabase
if ! grep -q "loadFromSupabase" lib/core/database/database_helper.dart; then
    cat >> lib/core/database/database_helper.dart << 'ENDOFSUPABASE'

  Future<void> loadFromSupabase() async {
    try {
      print('🔄 Synchronisation Supabase...');
      // Implémentez votre logique ici
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }
ENDOFSUPABASE
fi

# Vérifier et ajouter getTodayStats
if ! grep -q "getTodayStats" lib/core/database/database_helper.dart; then
    cat >> lib/core/database/database_helper.dart << 'ENDOFSTATS'

  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    
    final result = await db.query(
      'sales',
      where: 'sale_date >= ? AND sale_date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    
    final total = result.fold(0.0, (sum, row) => sum + (row['total_amount'] as double));
    return {
      'totalSales': result.length,
      'totalAmount': total,
      'averageAmount': result.isEmpty ? 0.0 : total / result.length,
    };
  }
ENDOFSTATS
fi

# Vérifier et ajouter getLowStockProducts
if ! grep -q "getLowStockProducts" lib/core/database/database_helper.dart; then
    cat >> lib/core/database/database_helper.dart << 'ENDOFLOW'

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'quantity <= min_stock',
    );
    return result.map((e) => Product.fromMap(e)).toList();
  }
ENDOFLOW
fi

# 4. Nettoyer les fichiers temporaires
echo "🧹 Nettoyage..."
flutter clean
flutter pub get

# 5. Analyser les erreurs
echo "📊 Analyse du code..."
flutter analyze 2>&1 | grep -E "(Error|Warning)" | head -20

echo "✅ Correction terminée !"
