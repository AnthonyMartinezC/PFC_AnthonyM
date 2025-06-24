import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/product_card.dart';
import '../models/producto.dart';

class MenPage extends StatefulWidget {
  const MenPage({super.key});

  @override
  State<MenPage> createState() => _MenPageState();
}

class _MenPageState extends State<MenPage> {
  final ScrollController _scrollController = ScrollController();
  List<Producto> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading) {
        // Aquí puedes implementar paginación real más adelante
      }
    });
  }

  void _loadProducts() async {
    setState(() => _isLoading = true);
    final productos = await FirebaseService.obtenerProductosPorCategoria('men');
    setState(() {
      _products = productos;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sombreros para Hombres")),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          return ProductCard(
            imageUrl: product.image_url,
            title: product.nombre,
            price: product.precio.toStringAsFixed(2),
          );
        },
      ),
    );
  }
}
