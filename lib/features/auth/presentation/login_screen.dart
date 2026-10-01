import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/local_auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/user.dart';
import '../../../shared/theme/app_theme.dart';
import '../../subscription/presentation/subscription_screen.dart';
import '../../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  bool _isOnline = true;

  @override
  void initState() { super.initState(); _checkConnectivity(); }

  Future<void> _checkConnectivity() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      setState(() => _isOnline = result != ConnectivityResult.none);
    } catch (e) { setState(() => _isOnline = false); }
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final result = await SupabaseService.signIn(email, password);
      print('DEBUG SUCCESS: ${result['success']}');

      if (result['success'] == true) {
        String barName = email.replaceAll('@gmail.com', '').toUpperCase();
        if (email.contains('caissier_')) {
          barName = email.replaceAll('caissier_', '').replaceAll('@gmail.com', '').toUpperCase();
        } else if (email.contains('vendeuse_')) {
          barName = email.replaceAll('vendeuse_', '').replaceAll('@gmail.com', '').toUpperCase();
        }

        String role = 'admin';
        if (email.contains('caissier_')) role = 'caissier';
        if (email.contains('vendeuse_')) role = 'serveur';

        final user = User(
          id: 0, username: email, password: '',
          fullName: email.split('@')[0],
          role: role,
          createdAt: 0, barName: barName,
        );

        AuthService.setCurrentUser(user);
        await DatabaseHelper().init();

        // Charger l'abonnement depuis Supabase
        await SubscriptionService.loadForBar(barName);
        final isActive = SubscriptionService.isSubscriptionActive(barName);
        print('DEBUG Abonnement actif: $isActive');

        if (user.isSuperAdmin || isActive || user.role == 'caissier' || user.role == 'serveur') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
        }
        return;
      }

      final localUser = LocalAuthService.authenticate(email, password);
      if (localUser != null) {
        final user = User.fromMap(localUser);
        AuthService.setCurrentUser(user);
        await DatabaseHelper().init();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        return;
      }

      setState(() => _errorMessage = result['message'] ?? 'Identifiants incorrects');
    } catch (e) {
      setState(() => _errorMessage = '❌ $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.darkBackground, AppTheme.cardBackground])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 100, height: 100, decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.local_drink, size: 60, color: AppTheme.primaryGold)),
                const SizedBox(height: 16),
                const Text('BARMASTER', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                const SizedBox(height: 40),
                Card(color: AppTheme.cardBackground, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      TextField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email, color: AppTheme.primaryGold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[800])),
                      const SizedBox(height: 16),
                      TextField(controller: _passwordCtrl, obscureText: _obscurePassword, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryGold), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[800])),
                      if (_errorMessage.isNotEmpty) Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.dangerRed.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(_errorMessage, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12))),
                      const SizedBox(height: 16),
                      SizedBox(height: 50, child: _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black), child: const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text("📝 Pas de compte ? S'inscrire", style: TextStyle(color: Colors.white70, fontSize: 13))),
                    ])),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
