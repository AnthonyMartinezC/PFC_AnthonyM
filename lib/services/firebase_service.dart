import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/producto.dart';
import 'auth_service.dart';

class FirebaseService {
  static final Random _random = Random();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generar UUID v4 sin dependencias externas
  static String _generateUUID() {
    const chars = 'abcdef0123456789';
    String uuid = '';

    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        uuid += '-';
      }
      if (i == 12) {
        uuid += '4'; // Versión 4
      } else if (i == 16) {
        uuid += ['8', '9', 'a', 'b'][_random.nextInt(4)]; // Variant bits
      } else {
        uuid += chars[_random.nextInt(chars.length)];
      }
    }
    return uuid;
  }

  // Método original que ya tenías
  static Future<List<Producto>> obtenerProductosPorCategoria(String categoria) async {
    final query = await _firestore
        .collection('productos')
        .where('categoria', isEqualTo: categoria)
        .get();

    return query.docs
        .map((doc) => Producto.fromMap(doc.id, doc.data()))
        .toList();
  }

  // NUEVO: Crear producto con UUID único (SOLO ADMINS)
  static Future<String> crearProductoConUUID({
    required String nombre,
    required String categoria,
    required String artesano,
    required double precio,
    String? descripcion,
    String? imagenUrl,
    Map<String, dynamic>? otrosDatos,
  }) async {
    // Verificar permisos de administrador
    AuthService.requireAdmin();

    try {
      // Generar UUID único para este producto
      final uuid = _generateUUID();

      // Verificar que el UUID no existe (casi imposible, pero por seguridad)
      final existeUUID = await _firestore
          .collection('productos')
          .where('uuid', isEqualTo: uuid)
          .get();

      if (existeUUID.docs.isNotEmpty) {
        // Si por alguna razón existe, generar otro
        return crearProductoConUUID(
          nombre: nombre,
          categoria: categoria,
          artesano: artesano,
          precio: precio,
          descripcion: descripcion,
          imagenUrl: imagenUrl,
          otrosDatos: otrosDatos,
        );
      }

      // Crear el documento del producto
      final docRef = await _firestore.collection('productos').add({
        'uuid': uuid,
        'nombre': nombre,
        'categoria': categoria,
        'artesano': artesano,
        'precio': precio,
        'descripcion': descripcion ?? '',
        'image_url': imagenUrl ?? '',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'creadoPor': AuthService.currentUserEmail,
        'verificado': true,
        'activo': true,
        ...?otrosDatos,
      });

      // Log para desarrollo (sin print en producción)
      debugLog('Producto creado con UUID: $uuid por ${AuthService.currentUserEmail}');
      return uuid;
    } catch (e) {
      debugLog('Error al crear producto: $e');
      throw Exception('Error al crear producto: $e');
    }
  }

  // NUEVO: Verificar autenticidad usando UUID del QR (USUARIOS Y ADMINS)
  static Future<Map<String, dynamic>?> verificarProductoPorUUID(String uuid) async {
    // Verificar que el usuario esté autenticado
    AuthService.requireAuth();

    try {
      final query = await _firestore
          .collection('productos')
          .where('uuid', isEqualTo: uuid)
          .where('activo', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        return {
          'esAutentico': false,
          'mensaje': 'Este sombrero no se encuentra registrado en nuestra base de datos.',
          'encontrado': false,
        };
      }

      final doc = query.docs.first;
      final data = doc.data();

      // Para usuarios normales, solo confirmar que existe
      if (!AuthService.isAdmin) {
        return {
          'esAutentico': true,
          'mensaje': '✅ Este sombrero está registrado y es auténtico.',
          'encontrado': true,
          'producto': {
            'nombre': data['nombre'],
            'artesano': data['artesano'],
            'imagenUrl': data['imagenUrl'],
          },
        };
      }

      // Para administradores, mostrar toda la información
      return {
        'id': doc.id,
        'esAutentico': true,
        'encontrado': true,
        'producto': data,
        'mensaje': '✅ Producto auténtico verificado (Vista Admin)',
      };
    } catch (e) {
      debugLog('Error al verificar producto: $e');
      return {
        'esAutentico': false,
        'mensaje': 'Error al verificar el producto. Intenta nuevamente.',
        'encontrado': false,
      };
    }
  }

  // NUEVO: Obtener todos los productos con sus UUIDs (SOLO ADMINS)
  static Future<List<Map<String, dynamic>>> obtenerTodosLosProductos() async {
    AuthService.requireAdmin();

    try {
      final query = await _firestore
          .collection('productos')
          .where('activo', isEqualTo: true)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        'uuid': doc.data()['uuid'],
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugLog('Error al obtener productos: $e');
      return [];
    }
  }

  // NUEVO: Generar UUID para productos existentes que no lo tengan (SOLO ADMINS)
  static Future<int> generarUUIDsParaProductosExistentes() async {
    AuthService.requireAdmin();

    try {
      // Buscar productos sin UUID
      final query = await _firestore
          .collection('productos')
          .where('uuid', isNull: true)
          .get();

      int contadorActualizados = 0;

      for (var doc in query.docs) {
        final nuevoUUID = _generateUUID();
        await doc.reference.update({
          'uuid': nuevoUUID,
          'actualizadoPor': AuthService.currentUserEmail,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
        contadorActualizados++;
        debugLog('UUID agregado a producto ${doc.id}: $nuevoUUID');
      }

      return contadorActualizados;
    } catch (e) {
      debugLog('Error al generar UUIDs: $e');
      throw Exception('Error al generar UUIDs: $e');
    }
  }

  // NUEVO: Buscar producto por UUID para el generador QR (SOLO ADMINS)
  static Future<Map<String, dynamic>?> buscarProductoPorNombre(String nombre) async {
    AuthService.requireAdmin();

    try {
      final query = await _firestore
          .collection('productos')
          .where('nombre', isEqualTo: nombre)
          .where('activo', isEqualTo: true)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return {
          'id': doc.id,
          'uuid': doc.data()['uuid'],
          ...doc.data(),
        };
      }
      return null;
    } catch (e) {
      debugLog('Error al buscar producto: $e');
      return null;
    }
  }

  // NUEVO: Desactivar producto (en lugar de eliminar) - SOLO ADMINS
  static Future<bool> desactivarProducto(String uuid) async {
    AuthService.requireAdmin();

    try {
      final query = await _firestore
          .collection('productos')
          .where('uuid', isEqualTo: uuid)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'activo': false,
          'desactivadoPor': AuthService.currentUserEmail,
          'fechaDesactivacion': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      debugLog('Error al desactivar producto: $e');
      return false;
    }
  }

  // NUEVO: Estadísticas de productos (SOLO ADMINS)
  static Future<Map<String, int>> obtenerEstadisticas() async {
    AuthService.requireAdmin();

    try {
      final totalQuery = await _firestore.collection('productos').get();
      final activosQuery = await _firestore
          .collection('productos')
          .where('activo', isEqualTo: true)
          .get();
      final conUUIDQuery = await _firestore
          .collection('productos')
          .where('uuid', isNull: false)
          .get();

      return {
        'total': totalQuery.docs.length,
        'activos': activosQuery.docs.length,
        'conUUID': conUUIDQuery.docs.length,
        'sinUUID': totalQuery.docs.length - conUUIDQuery.docs.length,
      };
    } catch (e) {
      debugLog('Error al obtener estadísticas: $e');
      return {};
    }
  }

  // Método para logging en desarrollo (reemplaza print)
  static void debugLog(String message) {
    // En desarrollo, puedes habilitar esto:
    // developer.log(message, name: 'FirebaseService');

    // En producción, esto se puede conectar a un servicio de logging
    // como Firebase Crashlytics o similar
  }
}