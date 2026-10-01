import 'dart:async';
import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/sales/presentation/new_sale_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/purchases/presentation/purchase_screen.dart';
import 'features/statistics/presentation/stats_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'shared/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'core/services/auth_service.dart';
import 'core/services/subscription_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/auto_backup_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await SupabaseService.init(); } catch (e) {}
  final db = DatabaseHelper();
  await db.init();
  try { await db.loadFromSupabase(); } catch (e) {}
  try { await AutoBackupService.startAutoBackup(); } catch (e) {}
  ConnectivityService().startMonitoring();
  runApp(const BarMasterApp());
}

class BarMasterApp extends StatelessWidget {
  const BarMasterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarMaster',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> _getScreens() {
    final user = AuthService.getCurrentUser();
    final screens = <Widget>[const DashboardScreen()];
    if (user?.canAccessSales ?? false) screens.add(const SaleScreen());
    if (user?.canAccessInventory ?? false) screens.add(const InventoryScreen());
    if (user?.canAccessPurchases ?? false) screens.add(const PurchaseScreen());
    if (user?.canAccessStats ?? false) screens.add(const StatsScreen());
    return screens;
  }

  List<BottomNavigationBarItem> _getNavItems() {
    final user = AuthService.getCurrentUser();
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Accueil'),
    ];
    if (user?.canAccessSales ?? false) items.add(const BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Vente'));
    if (user?.canAccessInventory ?? false) items.add(const BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'));
    if (user?.canAccessPurchases ?? false) items.add(const BottomNavigationBarItem(icon: Icon(Icons.add_shopping_cart), label: 'Achat'));
    if (user?.canAccessStats ?? false) items.add(const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'));
    return items;
  }

  void navigateTo(int index) {
    final screens = _getScreens();
    if (index < screens.length) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = AuthService.isOfflineMode();
    final screens = _getScreens();
    final navItems = _getNavItems();
    if (_selectedIndex >= screens.length) _selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AuthService.barName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text('Abonnement: ${SubscriptionService.getRemainingDays()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        actions: [
          if (isOffline)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8), margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: AppTheme.warningOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Text('📴', style: TextStyle(fontSize: 14))),
          if (AuthService.getCurrentUser()?.canAccessSettings ?? false)
            IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () { AuthService.logout(); Navigator.pushReplacementNamed(context, '/login'); }),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, backgroundColor: Colors.grey[900],
        selectedItemColor: AppTheme.primaryGold, unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex, onTap: navigateTo, items: navItems,
      ),
    );
  }
}
