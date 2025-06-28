import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lista de administradores autorizados
  static const List<String> _adminEmails = [
    'administrador@austrohatsspain.com',
    'anthony@gmail.com',
  ];

  // Obtener usuario actual
  static User? get currentUser => _auth.currentUser;

  // Verificar si el usuario actual es administrador
  static bool get isAdmin {
    final user = currentUser;
    if (user == null) return false;
    return _adminEmails.contains(user.email?.toLowerCase());
  }

  // Verificar si el usuario está autenticado
  static bool get isAuthenticated => currentUser != null;

  // Obtener email del usuario actual
  static String? get currentUserEmail => currentUser?.email;

  // Stream para escuchar cambios de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar sesión con email y contraseña
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Registrar nuevo usuario
  static Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Enviar email de restablecimiento de contraseña
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Error al enviar email de recuperación: $e');
    }
  }

  // Verificar permisos antes de ejecutar acciones de admin
  static void requireAdmin() {
    if (!isAuthenticated) {
      throw Exception('Debes iniciar sesión para realizar esta acción');
    }
    if (!isAdmin) {
      throw Exception('No tienes permisos de administrador para realizar esta acción');
    }
  }

  // Verificar permisos antes de ejecutar acciones que requieren autenticación
  static void requireAuth() {
    if (!isAuthenticated) {
      throw Exception('Debes iniciar sesión para realizar esta acción');
    }
  }

  // Obtener información del usuario para mostrar en UI
  static Map<String, dynamic> getUserInfo() {
    final user = currentUser;
    if (user == null) {
      return {
        'isAuthenticated': false,
        'isAdmin': false,
        'email': null,
        'displayName': null,
      };
    }

    return {
      'isAuthenticated': true,
      'isAdmin': isAdmin,
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@')[0],
      'uid': user.uid,
    };
  }
}