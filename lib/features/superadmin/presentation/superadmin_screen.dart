import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/subscription_service.dart';
import '../../../shared/theme/app_theme.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});
  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  void _generateKey() {
    final key = SubscriptionService.generateKey();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ Cle generee: $key'),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final users = _db.getAllUsers();
    final keys = [];

    return Scaffold(
      appBar: AppBar(title: const Text('🛡️ Super Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Générer clé
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('🔑 Generer une cle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _generateKey,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('GENERER UNE CLE DE 12 CHIFFRES'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black, padding: const EdgeInsets.all(14)),
                ),
              ]),
            ),
          ),

          // Clés disponibles
          if (keys.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Cles disponibles (${keys.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...keys.map((key) => Card(
              color: Colors.green.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.key, color: Colors.green),
                title: Text(key, style: const TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                subtitle: const Text('Utilisation unique', style: TextStyle(color: Colors.grey, fontSize: 10)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white70),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Cle copiee: $key')));
                  },
                ),
              ),
            )),
          ] else ...[
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucune cle disponible. Generez-en une.', style: TextStyle(color: Colors.grey))),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text('👥 Utilisateurs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ...users.map((u) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: u.isSuperAdmin ? Colors.purple : (u.isAdmin ? Colors.red : (u.isCaissier ? Colors.blue : Colors.green)),
                child: Text(u.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              title: Text(u.fullName),
              subtitle: Text('${u.role.toUpperCase()} - Bar: ${u.barName ?? "?"}'),
              trailing: u.isActive ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.cancel, color: Colors.red),
            ),
          )),
        ],
      ),
    );
  }
}
