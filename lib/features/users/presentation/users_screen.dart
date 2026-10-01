import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/user.dart';
import '../../../shared/theme/app_theme.dart';
import 'active_users_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<User> _users = [];
  bool _isLoading = true;

  // Contrôleurs pour le formulaire
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  String _selectedRole = 'caissier';
  int? _editingId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _db.addListener(_refreshData);
  }

  @override
  void dispose() {
    _db.removeListener(_refreshData);
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _refreshData() {
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _isLoading = true;
      try {
        _users = _db.getAllUsers();
      } catch (e) {
        print('❌ Erreur: $e');
      }
      _isLoading = false;
    });
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    _fullNameController.clear();
    setState(() {
      _editingId = null;
      _selectedRole = 'caissier';
    });
  }

  void _editUser(User user) {
    setState(() {
      _editingId = user.id;
      _usernameController.text = user.username;
      _fullNameController.text = user.fullName;
      _selectedRole = user.role;
    });
  }

  void _saveUser() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (username.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    if (_editingId == null && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un mot de passe'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    if (_editingId != null) {
      _db.updateUser(_editingId!, fullName, _selectedRole, true);
      if (password.isNotEmpty) {
        _db.updateUserPassword(_editingId!, password);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Utilisateur "$username" mis à jour'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      _db.addUser(username, password, fullName, _selectedRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Utilisateur "$username" ajouté'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }

    _resetForm();
    _loadUsers();
  }

  void _resetPassword(User user) {
    if (user.id == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Impossible de réinitialiser le mot de passe admin'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous réinitialiser le mot de passe de :',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              '👤 ${user.fullName} (@${user.username})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key, color: AppTheme.primaryGold),
                  const SizedBox(width: 12),
                  Text(
                    'Nouveau mot de passe : ${user.username}123',
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _db.updateUserPassword(user.id, '${user.username}123');
              Navigator.pop(context);
              _loadUsers();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Mot de passe réinitialisé pour ${user.username}'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGold,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(User user) {
    if (user.id == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Impossible de supprimer l\'administrateur principal'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Supprimer l\'utilisateur'),
        content: Text('Voulez-vous vraiment supprimer "${user.fullName}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _db.deleteUser(user.id);
              Navigator.pop(context);
              _loadUsers();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ Utilisateur supprimé'),
                  backgroundColor: AppTheme.warningOrange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActiveUsersScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulaire
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editingId != null ? '✏️ Modifier l\'utilisateur' : '➕ Ajouter un utilisateur',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _usernameController,
                            enabled: _editingId == null,
                            decoration: const InputDecoration(
                              labelText: 'Nom d\'utilisateur *',
                              hintText: 'Ex: caissier1',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: _editingId != null ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe *',
                              hintText: 'Min 6 caractères',
                              border: OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          TextField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet *',
                              hintText: 'Ex: Jean Dupont',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Rôle',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.security),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'admin', child: Text('👑 Administrateur')),
                              DropdownMenuItem(value: 'caissier', child: Text('💰 Caissier')),
                              DropdownMenuItem(value: 'serveur', child: Text('🍽️ Serveur')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: Text(
                                    _editingId != null ? 'Mettre à jour' : 'Ajouter',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (_editingId != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text('Annuler'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Liste des utilisateurs
                  Card(
                    color: AppTheme.cardBackground,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👥 Utilisateurs (${_users.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (_users.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Aucun utilisateur',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ..._users.map((user) {
                              final roleLabel = user.role == 'admin' ? '👑 Admin' : user.role == 'caissier' ? '💰 Caissier' : '🍽️ Serveur';
                              return Card(
                                color: user.isActive ? Colors.grey[800] : Colors.grey[800]!.withOpacity(0.5),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: user.role == 'admin' 
                                        ? AppTheme.primaryGold.withOpacity(0.2)
                                        : user.role == 'caissier'
                                          ? Colors.blue.withOpacity(0.2)
                                          : Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        user.role == 'admin' ? Icons.verified : Icons.person,
                                        color: user.role == 'admin' 
                                          ? AppTheme.primaryGold
                                          : user.role == 'caissier'
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user.fullName,
                                    style: TextStyle(
                                      color: user.isActive ? Colors.white : Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '@${user.username} - $roleLabel',
                                    style: TextStyle(
                                      color: user.isActive ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Bouton Réinitialiser mot de passe
                                      IconButton(
                                        icon: const Icon(Icons.lock_reset, 
                                          color: AppTheme.primaryGold),
                                        onPressed: () => _resetPassword(user),
                                      ),
                                      // Bouton Modifier
                                      IconButton(
                                        icon: const Icon(Icons.edit, 
                                          color: AppTheme.primaryGold),
                                        onPressed: () => _editUser(user),
                                      ),
                                      // Bouton Supprimer
                                      if (user.id != 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete, 
                                            color: AppTheme.dangerRed),
                                          onPressed: () => _deleteUser(user),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
