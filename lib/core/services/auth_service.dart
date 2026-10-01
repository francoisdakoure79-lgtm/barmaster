import '../database/database_helper.dart';
import '../database/models/user.dart';

class AuthService {
  static User? _currentUser;
  static bool _isOfflineMode = false;
  static String _barName = 'BARMASTER';
  static String _barAddress = '';
  static String _barPhone = '';
  static String _barEmail = '';

  static void setCurrentUser(User user) {
    _currentUser = user;
    _isOfflineMode = false;
    _barName = user.barName ?? 'BARMASTER';
    _barAddress = user.barAddress ?? '';
    _barPhone = user.barPhone ?? '';
    _barEmail = user.barEmail ?? '';
    
    // ✅ Réinitialiser et recharger pour cet utilisateur
    DatabaseHelper().resetForNewUser();
    DatabaseHelper().init();
    
    print('✅ Connecté: ${user.fullName} (${user.role}) - Bar: $_barName');
  }

  static void setOfflineMode(User user) {
    _currentUser = user;
    _isOfflineMode = true;
    _barName = user.barName ?? 'BARMASTER';
  }

  static User? getCurrentUser() => _currentUser;
  static String get barName => _barName;
  static String get barAddress => _barAddress;
  static String get barPhone => _barPhone;
  static String get barEmail => _barEmail;

  static void logout() {
    _currentUser = null;
    _isOfflineMode = false;
  }

  static bool isLoggedIn() => _currentUser != null;
  static bool isOfflineMode() => _isOfflineMode;
  static bool isAdmin() => _currentUser?.isAdmin ?? false;
  static bool isCaissier() => _currentUser?.isCaissier ?? false;
  static bool isServeur() => _currentUser?.isServeur ?? false;
  static bool isSuperAdmin() => _currentUser?.isSuperAdmin ?? false;
}
