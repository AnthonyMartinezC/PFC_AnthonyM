import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Your cart is empty.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
