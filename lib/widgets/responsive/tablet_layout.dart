import 'package:flutter/material.dart';

class TabletLayout extends StatelessWidget {
  const TabletLayout({super.key}); // Sin onLogout

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Style Up',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
  }
}