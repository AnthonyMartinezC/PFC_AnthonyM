import 'package:flutter/material.dart';
import 'login_page.dart';
import 'about_us_page.dart';
import 'men_page.dart';
import 'women_page.dart';
import 'contact_page.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/responsive/mobile_layout.dart';
import '../widgets/responsive/tablet_layout.dart';
import '../widgets/responsive/desktop_layout.dart';
import 'cart_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'qr_verify_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideText;
  late Animation<Offset> _slideButtons;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideText = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideButtons =
        Tween<Offset>(begin: const Offset(0.5, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
        );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.black.withAlpha((0.3 * 255).toInt()),
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _navItem("HOME", () {
                    // Evita abrir HomePage otra vez si ya estamos en ella
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }),
                  _navItem("ABOUT US", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsPage()),
                    );
                  }),
                  _navItem("MEN", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MenPage()),
                    );
                  }),
                  _navItem("WOMEN", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WomenPage()),
                    );
                  }),
                  _navItem("CONTACT", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactPage()),
                    );
                  }),
                ],
              ),
              if (MediaQuery.of(context).size.width >= 600)
                FirebaseAuth.instance.currentUser == null
                    ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text("LOGIN"),
                )
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: _logout,
                  child: const Text(
                    "LOGOUT",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideText,
              child: ResponsiveLayout(
                mobileBody: MobileLayout(onLogout: _logout),
                tabletBody: const TabletLayout(),
                desktopBody: const DesktopLayout(),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 60,
            child: SlideTransition(
              position: _slideButtons,
              child: Column(
                children: [
                  _floatingIcon(Icons.qr_code_scanner, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QRVerifyPage()),
                    );
                  }),
                  const SizedBox(height: 12),
                  _floatingIcon(Icons.shopping_cart, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _floatingIcon(IconData icon, VoidCallback onTap) {
    return ClipOval(
      child: Material(
        color: Colors.white,
        child: InkWell(
          splashColor: Colors.grey,
          onTap: onTap,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Icon(icon, color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
