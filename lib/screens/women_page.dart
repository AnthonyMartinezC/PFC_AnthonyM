import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/product_card.dart';
import '../models/producto.dart';

class WomenPage extends StatefulWidget {
  const WomenPage({super.key});

  @override
  State<WomenPage> createState() => _WomenPageState();
}

class _WomenPageState extends State<WomenPage> {
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
        // Aquí puedes implementar paginación más adelante
      }
    });
  }

  void _loadProducts() async {
    setState(() => _isLoading = true);
    final productos = await FirebaseService.obtenerProductosPorCategoria('women');
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
      appBar: AppBar(title: const Text("Sombreros para Mujeres")),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Dos columnas
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];
          return ProductCard(
            producto: product,    // ✅ Pasamos el objeto Producto completo
            categoria: 'women',   // ✅ Categoría para el carrito
          );
        },
      ),
    );
  }
}