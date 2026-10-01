import '../database/database_helper.dart';

class LocalAuthService {
  static final DatabaseHelper _db = DatabaseHelper();

  static Map<String, dynamic>? authenticate(String username, String password) {
    try {
      // ✅ Super admin codé en dur
      if (username == 'superadmin' && password == 'superadmin123') {
        return {
          'id': 0,
          'username': 'superadmin',
          'password': 'superadmin123',
          'fullName': 'Super Admin',
          'role': 'superadmin',
          'isActive': true,
          'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'barName': 'BARMASTER',
          'barAddress': '',
          'barPhone': '',
          'barEmail': '',
          'barManager': '',
        };
      }

      // Chercher dans TOUS les utilisateurs de la base locale
      final allUsers = _db.getAllUsers();
      for (var user in allUsers) {
        if (user.username == username && user.password == password) {
          return {
            'id': user.id,
            'username': user.username,
            'password': user.password,
            'fullName': user.fullName,
            'role': user.role,
            'isActive': user.isActive,
            'createdAt': user.createdAt,
            'barName': user.barName,
            'barAddress': user.barAddress,
            'barPhone': user.barPhone,
            'barEmail': user.barEmail,
            'barManager': user.barManager,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur authentification: $e');
      return null;
    }
  }
}
