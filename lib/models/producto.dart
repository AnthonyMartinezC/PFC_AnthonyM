class Producto {
  final String id;
  final String nombre;
  final double precio;
  final String image_url;
  final String categoria;
  final String descripcion;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.image_url,
    required this.categoria,
    required this.descripcion,
  });

  factory Producto.fromMap(String id, Map<String, dynamic> data) {
    return Producto(
      id: id,
      nombre: data['nombre'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      image_url: data['image_url'] ?? '',
      categoria: data['categoria'] ?? '',
      descripcion: data['descripcion'] ?? '',
    );
  }
}
