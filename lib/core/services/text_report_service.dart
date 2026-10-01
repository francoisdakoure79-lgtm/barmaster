import 'auth_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../database/models/product.dart';

class TextReportService {
  static final DatabaseHelper _db = DatabaseHelper();

  static bool get isWeb => kIsWeb;

  // ============================================================
  // RAPPORT JOURNALIER
  // ============================================================
  static Future<String> generateDailyReport(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startTimestamp = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endOfDay.millisecondsSinceEpoch ~/ 1000;

    final allSales = _db.getAllSales();
    final daySales = allSales.where((s) => 
      s.saleDate >= startTimestamp && s.saleDate < endTimestamp
    ).toList();

    final products = _db.getAllProducts();
    final totalAmount = daySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final ticketCount = daySales.length;

    final paymentCounts = <String, int>{};
    for (var sale in daySales) {
      paymentCounts[sale.paymentMethod] = (paymentCounts[sale.paymentMethod] ?? 0) + 1;
    }

    // Récupérer les infos du bar
    final barConfig = _db.getBarConfig();
    final barName = AuthService.barName;
    final barAddress = barConfig.address.isNotEmpty ? barConfig.address : '';
    final barPhone = AuthService.barPhone;
    final barSlogan = AuthService.barEmail;

    StringBuffer sb = StringBuffer();
    sb.writeln('=' * 60);
    sb.writeln('           ${barName.toUpperCase()}');
    if (barSlogan.isNotEmpty) sb.writeln('           $barSlogan');
    if (barAddress.isNotEmpty) sb.writeln('           $barAddress');
    if (barPhone.isNotEmpty) sb.writeln('           $barPhone');
    sb.writeln('=' * 60);
    sb.writeln('           RAPPORT JOURNALIER');
    sb.writeln('           Date: ${date.day}/${date.month}/${date.year}');
    sb.writeln('=' * 60);
    sb.writeln('');
    sb.writeln('📊 RÉSUMÉ');
    sb.writeln('   Total des ventes: ${totalAmount.toStringAsFixed(0)} FCFA');
    sb.writeln('   Nombre de tickets: $ticketCount');
    sb.writeln('   Produits en stock: ${products.length}');
    sb.writeln('');

    if (paymentCounts.isNotEmpty) {
      sb.writeln('💳 MODES DE PAIEMENT');
      for (var entry in paymentCounts.entries) {
        sb.writeln('   ${entry.key}: ${entry.value} ticket(s)');
      }
      sb.writeln('');
    }

    if (daySales.isNotEmpty) {
      sb.writeln('🛒 DÉTAIL DES VENTES');
      for (var sale in daySales) {
        final dateStr = DateTime.fromMillisecondsSinceEpoch(sale.saleDate * 1000);
        sb.writeln('   Ticket: ${sale.ticketNumber} - ${dateStr.day}/${dateStr.month}/${dateStr.year} ${dateStr.hour}:${dateStr.minute.toString().padLeft(2, '0')} - ${sale.totalAmount.toStringAsFixed(0)} FCFA');
      }
      sb.writeln('');
    }

    sb.writeln('📦 PRODUITS EN STOCK');
    for (var product in products) {
      final status = product.currentStock <= product.minStockThreshold ? '⚠️' : '✅';
      sb.writeln('   $status ${product.name}: ${product.currentStock} / ${product.minStockThreshold} (seuil)');
    }
    sb.writeln('');
    sb.writeln('=' * 60);
    sb.writeln('   Généré le ${DateTime.now().toString().substring(0, 16)}');
    sb.writeln('=' * 60);

    return sb.toString();
  }

  // ============================================================
  // RAPPORT MENSUEL
  // ============================================================
  static Future<String> generateMonthlyReport(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final allSales = _db.getAllSales();
    final monthSales = allSales.where((s) => 
      s.saleDate >= startTimestamp && s.saleDate < endTimestamp
    ).toList();

    final products = _db.getAllProducts();
    final totalAmount = monthSales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final ticketCount = monthSales.length;
    final averageTicket = ticketCount > 0 ? totalAmount / ticketCount : 0;

    final paymentCounts = <String, int>{};
    for (var sale in monthSales) {
      paymentCounts[sale.paymentMethod] = (paymentCounts[sale.paymentMethod] ?? 0) + 1;
    }

    final dailySales = <int, double>{};
    for (var sale in monthSales) {
      final day = DateTime.fromMillisecondsSinceEpoch(sale.saleDate * 1000).day;
      dailySales[day] = (dailySales[day] ?? 0) + sale.totalAmount;
    }

    // Récupérer les infos du bar
    final barConfig = _db.getBarConfig();
    final barName = AuthService.barName;
    final barAddress = barConfig.address.isNotEmpty ? barConfig.address : '';
    final barPhone = AuthService.barPhone;
    final barSlogan = AuthService.barEmail;

    final monthName = _getMonthName(month);
    StringBuffer sb = StringBuffer();
    sb.writeln('=' * 60);
    sb.writeln('           ${barName.toUpperCase()}');
    if (barSlogan.isNotEmpty) sb.writeln('           $barSlogan');
    if (barAddress.isNotEmpty) sb.writeln('           $barAddress');
    if (barPhone.isNotEmpty) sb.writeln('           $barPhone');
    sb.writeln('=' * 60);
    sb.writeln('           RAPPORT MENSUEL');
    sb.writeln('           $monthName $year');
    sb.writeln('=' * 60);
    sb.writeln('');
    sb.writeln('📊 RÉSUMÉ MENSUEL');
    sb.writeln('   Total des ventes: ${totalAmount.toStringAsFixed(0)} FCFA');
    sb.writeln('   Nombre de tickets: $ticketCount');
    sb.writeln('   Panier moyen: ${averageTicket.toStringAsFixed(0)} FCFA');
    sb.writeln('   Produits en stock: ${products.length}');
    sb.writeln('');

    if (paymentCounts.isNotEmpty) {
      sb.writeln('💳 MODES DE PAIEMENT');
      for (var entry in paymentCounts.entries) {
        sb.writeln('   ${entry.key}: ${entry.value} ticket(s)');
      }
      sb.writeln('');
    }

    if (dailySales.isNotEmpty) {
      sb.writeln('📈 ÉVOLUTION JOURNALIÈRE');
      final sortedKeys = dailySales.keys.toList()..sort();
      for (var day in sortedKeys) {
        sb.writeln('   Jour $day: ${dailySales[day]?.toStringAsFixed(0) ?? 0} FCFA');
      }
      sb.writeln('');
    }

    sb.writeln('📦 PRODUITS EN STOCK');
    for (var product in products) {
      final status = product.currentStock <= product.minStockThreshold ? '⚠️' : '✅';
      sb.writeln('   $status ${product.name}: ${product.currentStock} / ${product.minStockThreshold} (seuil)');
    }
    sb.writeln('');
    sb.writeln('=' * 60);
    sb.writeln('   Généré le ${DateTime.now().toString().substring(0, 16)}');
    sb.writeln('=' * 60);

    return sb.toString();
  }

  // ============================================================
  // RAPPORT ANNUEL
  // ============================================================
  static Future<String> generateYearlyReport(int year) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year + 1, 1, 1);
    final startTimestamp = startDate.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endDate.millisecondsSinceEpoch ~/ 1000;

    final allSales = _db.getAllSales();
    final yearSales = allSales.where((s) => 
      s.saleDate >= startTimestamp && s.saleDate < endTimestamp
    ).toList();

    final products = _db.getAllProducts();
    final totalAmount = yearSales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final ticketCount = yearSales.length;
    final averageTicket = ticketCount > 0 ? totalAmount / ticketCount : 0;

    final monthlyStats = <int, double>{};
    for (int month = 1; month <= 12; month++) {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 1);
      final mStartTs = monthStart.millisecondsSinceEpoch ~/ 1000;
      final mEndTs = monthEnd.millisecondsSinceEpoch ~/ 1000;
      
      double monthTotal = 0;
      for (var sale in yearSales) {
        if (sale.saleDate >= mStartTs && sale.saleDate < mEndTs) {
          monthTotal += sale.totalAmount;
        }
      }
      monthlyStats[month] = monthTotal;
    }

    // Récupérer les infos du bar
    final barConfig = _db.getBarConfig();
    final barName = AuthService.barName;
    final barAddress = barConfig.address.isNotEmpty ? barConfig.address : '';
    final barPhone = AuthService.barPhone;
    final barSlogan = AuthService.barEmail;

    StringBuffer sb = StringBuffer();
    sb.writeln('=' * 60);
    sb.writeln('           ${barName.toUpperCase()}');
    if (barSlogan.isNotEmpty) sb.writeln('           $barSlogan');
    if (barAddress.isNotEmpty) sb.writeln('           $barAddress');
    if (barPhone.isNotEmpty) sb.writeln('           $barPhone');
    sb.writeln('=' * 60);
    sb.writeln('           RAPPORT ANNUEL');
    sb.writeln('           Année $year');
    sb.writeln('=' * 60);
    sb.writeln('');
    sb.writeln('📊 RÉSUMÉ ANNUEL');
    sb.writeln('   Total des ventes: ${totalAmount.toStringAsFixed(0)} FCFA');
    sb.writeln('   Nombre de tickets: $ticketCount');
    sb.writeln('   Panier moyen: ${averageTicket.toStringAsFixed(0)} FCFA');
    sb.writeln('   Produits en stock: ${products.length}');
    sb.writeln('');

    sb.writeln('📈 ÉVOLUTION MENSUELLE');
    for (int month = 1; month <= 12; month++) {
      final monthName = _getMonthName(month);
      final value = monthlyStats[month] ?? 0;
      final barLength = (value / 10000).toInt();
      final bar = '█' * (barLength > 50 ? 50 : barLength);
      sb.writeln('   $monthName: ${value.toStringAsFixed(0)} FCFA $bar');
    }
    sb.writeln('');

    sb.writeln('📦 PRODUITS EN STOCK');
    final sortedProducts = List<Product>.from(products)..sort((a, b) => a.currentStock.compareTo(b.currentStock));
    final bestSeller = sortedProducts.firstWhere((p) => p.currentStock < p.minStockThreshold, orElse: () => sortedProducts.first);
    
    sb.writeln('   🏆 Meilleur vendeur: ${bestSeller.name} (Stock: ${bestSeller.currentStock})');
    sb.writeln('');
    
    for (var product in products) {
      final status = product.currentStock <= product.minStockThreshold ? '⚠️' : '✅';
      sb.writeln('   $status ${product.name}: ${product.currentStock} / ${product.minStockThreshold} (seuil)');
    }
    sb.writeln('');
    sb.writeln('=' * 60);
    sb.writeln('   Généré le ${DateTime.now().toString().substring(0, 16)}');
    sb.writeln('=' * 60);

    return sb.toString();
  }

  // ============================================================
  // SAUVEGARDE
  // ============================================================
  static Future<void> saveReport(String content, String filename) async {
    try {
      if (isWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('report_$filename', content);
        print('✅ Rapport sauvegardé (web): $filename');
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        final reportsDir = Directory('${appDocDir.path}/rapports');
        if (!await reportsDir.exists()) {
          await reportsDir.create(recursive: true);
        }
        final file = File('${reportsDir.path}/$filename.txt');
        await file.writeAsString(content);
        print('✅ Rapport sauvegardé: ${file.path}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      rethrow;
    }
  }

  static Future<String?> getSavedReport(String filename) async {
    try {
      if (isWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('report_$filename');
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        final file = File('${appDocDir.path}/rapports/$filename.txt');
        if (await file.exists()) {
          return await file.readAsString();
        }
        return null;
      }
    } catch (e) {
      print('❌ Erreur lecture: $e');
      return null;
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================
  static String _getMonthName(int month) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[month - 1];
  }
}
