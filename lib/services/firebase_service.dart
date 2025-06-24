import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';

class FirebaseService {
  static Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    final query = await FirebaseFirestore.instance
        .collection('productos')
        .where('categoria', isEqualTo: categoria)
        .get();

    return query.docs
        .map((doc) => Producto.fromMap(doc.id, doc.data()))
        .toList();
  }
}
