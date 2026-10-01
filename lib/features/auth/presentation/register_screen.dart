import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _idExpiryCtrl = TextEditingController();
  final _barNameCtrl = TextEditingController();
  final _barAddressCtrl = TextEditingController();
  final _barPhoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose(); _lastNameCtrl.dispose(); _firstNameCtrl.dispose();
    _idNumberCtrl.dispose(); _idExpiryCtrl.dispose(); _barNameCtrl.dispose();
    _barAddressCtrl.dispose(); _barPhoneCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mots de passe differents')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper();
      final email = _emailCtrl.text.trim();
      final barName = _barNameCtrl.text.trim();
      final barPhone = _barPhoneCtrl.text.trim();
      final barAddress = _barAddressCtrl.text.trim();
      final fullName = '${_firstNameCtrl.text} ${_lastNameCtrl.text}';

      // Créer le compte Supabase Auth
      try {
        await SupabaseService.signUp(email: email, password: _passwordCtrl.text, fullName: fullName, role: 'admin', barName: barName);
        print('✅ Compte Supabase Auth créé');
      } catch (e) {}

      // Créer l'admin localement
      await db.addUser(email, _passwordCtrl.text, fullName, 'admin',
          barName: barName, barAddress: barAddress, barPhone: barPhone);

      // Créer caissier
      await db.addUser('caissier_${_firstNameCtrl.text.trim().toLowerCase()}',
          'caissier123', 'Caissier', 'caissier',
          barName: barName, barAddress: barAddress, barPhone: barPhone);

      // Créer caissier dans Supabase Auth
      try {
        await SupabaseService.signUp(
          email: 'caissier_${_firstNameCtrl.text.trim().toLowerCase()}@gmail.com',
          password: 'caissier123',
          fullName: 'Caissier',
          role: 'caissier',
          barName: barName,
        );
      } catch (e) {}

      // Créer vendeuse
      await db.addUser('vendeuse_${_firstNameCtrl.text.trim().toLowerCase()}',
          'vendeuse123', 'Vendeuse', 'serveur',
          barName: barName, barAddress: barAddress, barPhone: barPhone);

      // Créer vendeuse dans Supabase Auth
      try {
        await SupabaseService.signUp(
          email: 'vendeuse_${_firstNameCtrl.text.trim().toLowerCase()}@gmail.com',
          password: 'vendeuse123',
          fullName: 'Vendeuse',
          role: 'serveur',
          barName: barName,
        );
      } catch (e) {}

      // Fusionner les users dans global
      try {
        final existingData = await SupabaseService.loadData('global');
        final existingUsers = existingData?['users'] as List? ?? [];
        final newUsers = [
          {'id': 1, 'username': email, 'password': _passwordCtrl.text, 'fullName': fullName, 'role': 'admin', 'barName': barName},
          {'id': 2, 'username': 'caissier_${_firstNameCtrl.text.trim().toLowerCase()}', 'password': 'caissier123', 'fullName': 'Caissier', 'role': 'caissier', 'barName': barName},
          {'id': 3, 'username': 'vendeuse_${_firstNameCtrl.text.trim().toLowerCase()}', 'password': 'vendeuse123', 'fullName': 'Vendeuse', 'role': 'serveur', 'barName': barName},
        ];
        final allUsers = [...existingUsers, ...newUsers];
        await SupabaseService.saveData('global', {'users': allUsers});
        print('✅ Users fusionnés dans global');
      } catch (e) {
        print('❌ Erreur global: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Bar créé !\nCaissier: caissier_${_firstNameCtrl.text.trim().toLowerCase()} / caissier123\nVendeuse: vendeuse_${_firstNameCtrl.text.trim().toLowerCase()} / vendeuse123'),
          duration: const Duration(seconds: 8),
        ),
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.darkBackground, AppTheme.cardBackground])),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(children: [
                const Icon(Icons.local_drink, size: 50, color: AppTheme.primaryGold),
                const SizedBox(height: 8),
                const Text('CREER UN COMPTE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                const SizedBox(height: 20),
                _tf('Email (identifiant)', _emailCtrl, required: true),
                _tf('Nom', _lastNameCtrl),
                _tf('Prenom', _firstNameCtrl),
                _tf('N° piece', _idNumberCtrl),
                _tf('Date expiration', _idExpiryCtrl),
                const SizedBox(height: 16),
                _tf('Nom du bar', _barNameCtrl, required: true),
                _tf('Adresse', _barAddressCtrl),
                _tf('Telephone', _barPhoneCtrl),
                const SizedBox(height: 16),
                TextFormField(controller: _passwordCtrl, obscureText: _obscure, validator: (v) => v!.length < 6 ? '6 caracteres min' : null, decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryGold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[800]), style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                TextFormField(controller: _confirmCtrl, obscureText: true, validator: (v) => v != _passwordCtrl.text ? 'Differents' : null, decoration: InputDecoration(labelText: 'Confirmer', prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[800]), style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: _isLoading ? const CircularProgressIndicator() : const Text('CREER UN COMPTE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 12),
                TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Deja un compte ? Se connecter', style: TextStyle(color: Colors.white70))),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tf(String label, TextEditingController ctrl, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(controller: ctrl, validator: required ? (v) => v!.isEmpty ? 'Requis' : null : null, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[800]), style: const TextStyle(color: Colors.white)),
    );
  }
}
