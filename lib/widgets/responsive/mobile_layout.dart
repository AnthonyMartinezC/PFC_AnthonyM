import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/login_page.dart';

class MobileLayout extends StatelessWidget {
  final VoidCallback onLogout;

  const MobileLayout({super.key, required this.onLogout});

  Future<void> _logoutWithSnackBar(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Sesión cerrada. ¡Hasta pronto!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Style up',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: user != null ? Colors.white : Colors.green,
                  foregroundColor: user != null ? Colors.black : Colors.white,
                ),
                onPressed: () {
                  if (user != null) {
                    _logoutWithSnackBar(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                },
                child: Text(user != null ? 'LOGOUT' : 'LOGIN'),
              );
            },
          ),
        ],
      ),
    );
  }
}