import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/user.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';

class TeamBarScreen extends StatefulWidget {
  const TeamBarScreen({super.key});
  @override
  State<TeamBarScreen> createState() => _TeamBarScreenState();
}

class _TeamBarScreenState extends State<TeamBarScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsers = _db.getAllUsers();
    final currentBar = AuthService.barName;
    final isSuperAdmin = AuthService.getCurrentUser()?.isSuperAdmin ?? false;
    final users = allUsers.where((u) {
      if (u.isSuperAdmin) return isSuperAdmin; // Super admin ne voit que lui
      if (isSuperAdmin) return true; // Super admin voit tout
      return u.barName == currentBar; // Admin voit son personnel uniquement
    }).toList();
    final config = _db.getBarConfig();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe & Bar'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Equipe'),
            Tab(icon: Icon(Icons.store), text: 'Mon Bar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(users),
          if (AuthService.getCurrentUser()?.isSuperAdmin == true) _buildBarTab(config),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
    );
  }

  Widget _buildUsersTab(List<User> users) {
    return users.isEmpty
        ? const Center(child: Text('Aucun utilisateur', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: u.isAdmin ? Colors.red : (u.isCaissier ? Colors.blue : Colors.green),
                    child: Text(u.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(u.fullName),
                  subtitle: Text('${u.role.toUpperCase()} - ${u.username}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.orange), onPressed: () => _showUserDialog(user: u)),
                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteUser(u)),
                  ]),
                ),
              );
            },
          );
  }

  Widget _buildBarTab(dynamic config) {
    final isSuperAdmin = AuthService.getCurrentUser()?.isSuperAdmin ?? false;
    if (!isSuperAdmin) {
      return const Center(child: Text('Acces reserve au Super Admin', style: TextStyle(color: Colors.grey)));
    }
    final nameCtrl = TextEditingController(text: config.name);
    final addressCtrl = TextEditingController(text: config.address);
    final phoneCtrl = TextEditingController(text: config.phone);
    final emailCtrl = TextEditingController(text: config.email);
    final sloganCtrl = TextEditingController(text: config.slogan);
    final managerCtrl = TextEditingController(text: config.manager);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Informations du Bar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        _tf('Nom du bar', nameCtrl), _tf('Adresse', addressCtrl), _tf('Telephone', phoneCtrl),
        _tf('Email', emailCtrl), _tf('Slogan', sloganCtrl), _tf('Gerant', managerCtrl),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _db.updateBarConfig(name: nameCtrl.text, address: addressCtrl.text, phone: phoneCtrl.text, email: emailCtrl.text, slogan: sloganCtrl.text, manager: managerCtrl.text);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Bar mis a jour')));
            setState(() {});
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black, padding: const EdgeInsets.all(14)),
          child: const Text('Enregistrer', style: TextStyle(fontSize: 16)),
        ),
      ]),
    );
  }

  Widget _tf(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl, style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey[800]),
      ),
    );
  }

  void _showUserDialog({User? user}) {
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final passwordCtrl = TextEditingController(text: user?.password ?? '');
    String role = user?.role ?? 'serveur';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user == null ? 'Nouvel utilisateur' : 'Modifier ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom complet'), style: const TextStyle(color: Colors.white)),
            TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Identifiant'), style: const TextStyle(color: Colors.white)),
            TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), style: const TextStyle(color: Colors.white), obscureText: true),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: role, decoration: const InputDecoration(labelText: 'Role'), dropdownColor: Colors.grey[800], style: const TextStyle(color: Colors.white),
              items: const [DropdownMenuItem(value: 'caissier', child: Text('Caissier')), DropdownMenuItem(value: 'serveur', child: Text('Vendeuse'))],
              onChanged: (v) => role = v!,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (user == null) {
                final error = _db.addUser(usernameCtrl.text, passwordCtrl.text, nameCtrl.text, role);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
              } else {
                _db.updateUser(user.id, fullName: nameCtrl.text, role: role);
              }
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(user == null ? '✅ Cree' : '✅ Modifie')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
            child: Text(user == null ? 'Creer' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer ${user.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { _db.deleteUser(user.id); Navigator.pop(ctx); setState(() {}); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
  }
}
