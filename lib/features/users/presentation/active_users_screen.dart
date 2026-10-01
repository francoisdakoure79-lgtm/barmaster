import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/user.dart';
import '../../../shared/theme/app_theme.dart';

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key});

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _db.addListener(_refreshData);
  }

  @override
  void dispose() {
    _db.removeListener(_refreshData);
    super.dispose();
  }

  void _refreshData() {
    _loadUsers();
  }

  void _loadUsers() {
    setState(() => _isLoading = true);
    try {
      _users = _db.getAllUsers()
        ..sort((a, b) => (b.lastLogin ?? 0).compareTo(a.lastLogin ?? 0));
    } catch (e) {
      print('❌ Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'Jamais';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _getStatusText(User user) {
    if (!user.isActive) return '❌ Désactivé';
    if (user.lastLogin == null) return '📅 Jamais connecté';
    final lastLogin = DateTime.fromMillisecondsSinceEpoch(user.lastLogin! * 1000);
    final diff = DateTime.now().difference(lastLogin);
    if (diff.inDays > 7) return '🟡 Inactif (>7 jours)';
    if (diff.inDays > 1) return '🟢 Actif (récemment)';
    return '🟢 Actif (aujourd\'hui)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Utilisateurs actifs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun utilisateur',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      color: AppTheme.cardBackground,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin 
                            ? AppTheme.primaryGold.withOpacity(0.2) 
                            : user.isCaissier
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          child: Text(
                            user.fullName[0].toUpperCase(),
                            style: TextStyle(
                              color: user.isAdmin 
                                ? AppTheme.primaryGold 
                                : user.isCaissier
                                  ? Colors.blue
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${user.username} · ${user.role.toUpperCase()}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            Text(
                              _getStatusText(user),
                              style: TextStyle(
                                color: user.isActive ? AppTheme.successGreen : Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              user.isActive ? Icons.circle : Icons.circle_outlined,
                              color: user.isActive ? AppTheme.successGreen : Colors.grey,
                              size: 12,
                            ),
                            Text(
                              'Dernière connexion',
                              style: TextStyle(color: Colors.grey[500], fontSize: 9),
                            ),
                            Text(
                              _formatDate(user.lastLogin),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
