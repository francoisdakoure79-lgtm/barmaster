import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _message = '';
  Color _messageColor = AppTheme.successGreen;

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _message = 'Veuillez remplir tous les champs';
        _messageColor = AppTheme.warningOrange;
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _message = 'Le nouveau mot de passe doit faire au moins 6 caractères';
        _messageColor = AppTheme.warningOrange;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _message = 'Les mots de passe ne correspondent pas';
        _messageColor = AppTheme.dangerRed;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final user = AuthService.getCurrentUser();
      if (user == null) {
        setState(() {
          _message = 'Utilisateur non connecté';
          _messageColor = AppTheme.dangerRed;
        });
        _isLoading = false;
        return;
      }

      // Vérifier l'ancien mot de passe
      if (user.password != oldPassword) {
        setState(() {
          _message = 'Ancien mot de passe incorrect';
          _messageColor = AppTheme.dangerRed;
        });
        _isLoading = false;
        return;
      }

      // Mettre à jour le mot de passe
      _db.updateUserPassword(user.id, newPassword);
      
      setState(() {
        _message = '✅ Mot de passe modifié avec succès !';
        _messageColor = AppTheme.successGreen;
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mot de passe modifié !'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

    } catch (e) {
      setState(() {
        _message = '❌ Erreur: $e';
        _messageColor = AppTheme.dangerRed;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changer le mot de passe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '🔐 Changer votre mot de passe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ancien mot de passe
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOld,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ancien mot de passe',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureOld ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureOld = !_obscureOld;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nouveau mot de passe
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe (min 6 caractères)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryGold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirmation
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryGold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message
                    if (_message.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _messageColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message,
                          style: TextStyle(color: _messageColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Bouton
                    SizedBox(
                      height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Changer le mot de passe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
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
