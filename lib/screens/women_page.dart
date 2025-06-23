import 'package:flutter/material.dart';
import '../widgets/product_card.dart';

class WomenPage extends StatefulWidget {
  const WomenPage({super.key});

  @override
  State<WomenPage> createState() => _WomenPageState();
}

class _WomenPageState extends State<WomenPage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _products = List.generate(10, (index) => {
    'title': 'Sombrero Mujer ${index + 1}',
    'price': '49.99',
    'image': 'assets/images/sombrero2.jpg' // Usa otra imagen si quieres
  });
  bool _isLoading = false;

  void _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2)); // Simula carga

    setState(() {
      _products.addAll(List.generate(6, (index) => {
        'title': 'Sombrero Mujer ${_products.length + index + 1}',
        'price': '49.99',
        'image': 'assets/images/sombrero2.jpg'
      }));
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading) {
        _loadMore();
      }
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
      body: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _products.length + 1,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Dos columnas
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          if (index < _products.length) {
            final product = _products[index];
            return ProductCard(
              imageUrl: product['image'] ?? '',
              title: product['title'] ?? '',
              price: product['price'] ?? '',
            );
          } else {
            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
