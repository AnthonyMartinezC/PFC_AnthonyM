import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Modelo del item del carrito adaptado para Firebase
class CartItem {
  final String id;
  final String name;
  final double price;
  final String category; // 'men' o 'women'
  final String? imageUrl;
  final String? artisan;
  final String? descripcion;
  final String? uuid; // Para el sistema QR
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.artisan,
    this.descripcion,
    this.uuid,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? imageUrl,
    String? artisan,
    String? descripcion,
    String? uuid,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      artisan: artisan ?? this.artisan,
      descripcion: descripcion ?? this.descripcion,
      uuid: uuid ?? this.uuid,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'artisan': artisan,
      'descripcion': descripcion,
      'uuid': uuid,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? map['nombre'] ?? '',
      price: map['price']?.toDouble() ?? map['precio']?.toDouble() ?? 0.0,
      category: map['category'] ?? map['categoria'] ?? '',
      imageUrl: map['imageUrl'] ?? map['imagenUrl'],
      artisan: map['artisan'] ?? map['artesano'],
      descripcion: map['descripcion'],
      uuid: map['uuid'],
      quantity: map['quantity']?.toInt() ?? 1,
    );
  }

  // Crear CartItem desde documento de Firebase
  factory CartItem.fromFirebaseDoc(String docId, Map<String, dynamic> data, {int quantity = 1}) {
    return CartItem(
      id: docId,
      name: data['nombre'] ?? '',
      price: data['precio']?.toDouble() ?? 0.0,
      category: data['categoria'] ?? '',
      imageUrl: data['imagenUrl'],
      artisan: data['artesano'],
      descripcion: data['descripcion'],
      uuid: data['uuid'],
      quantity: quantity,
    );
  }
}

// Servicio del carrito integrado con Firebase y persistencia automática
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal() {
    _initializeAuthListener();
  }

  final List<CartItem> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSubscription;
  Timer? _saveTimer;
  bool _isLoading = false;
  bool _hasLoadedFromFirebase = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;

  // Escuchar cambios de autenticación
  void _initializeAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Usuario se autenticó - cargar carrito
        _loadCartFromFirebaseAuto();
      } else {
        // Usuario cerró sesión - limpiar carrito local
        _clearLocalCart();
      }
    });
  }

  // Cargar carrito automáticamente (sin notificar errores al usuario)
  Future<void> _loadCartFromFirebaseAuto() async {
    if (_hasLoadedFromFirebase) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('carritos').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final itemsList = data['items'] as List? ?? [];

        _items.clear();
        for (var itemData in itemsList) {
          _items.add(CartItem.fromMap(itemData));
        }

        _hasLoadedFromFirebase = true;
        debugPrint('✅ Carrito cargado desde Firebase: ${_items.length} items');
      }
    } catch (e) {
      debugPrint('❌ Error al cargar carrito desde Firebase: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar carrito local sin afectar Firebase
  void _clearLocalCart() {
    _items.clear();
    _hasLoadedFromFirebase = false;
    _saveTimer?.cancel();
    notifyListeners();
    debugPrint('🧹 Carrito local limpiado');
  }

  // Auto-guardar con delay para evitar múltiples escrituras
  void _scheduleAutoSave() {
    final user = _auth.currentUser;
    if (user == null) return;

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveCartToFirebaseAuto();
    });
  }

  // Guardar carrito automáticamente (sin notificar errores al usuario)
  Future<void> _saveCartToFirebaseAuto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartData = {
        'items': _items.map((item) => item.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalItems': itemCount,
        'totalPrice': totalPrice,
        'userId': user.uid,
      };

      await _firestore.collection('carritos').doc(user.uid).set(cartData);
      debugPrint('💾 Carrito guardado automáticamente en Firebase');
    } catch (e) {
      debugPrint('❌ Error al guardar carrito automáticamente: $e');
    }
  }

  // Agregar producto al carrito desde Firebase por ID
  Future<bool> addItemFromFirebase(String firebaseDocId, {int quantity = 1}) async {
    try {
      final doc = await _firestore.collection('productos').doc(firebaseDocId).get();

      if (!doc.exists) {
        debugPrint('Producto no encontrado en Firebase: $firebaseDocId');
        return false;
      }

      final data = doc.data()!;
      final existingIndex = _items.indexWhere((item) => item.id == firebaseDocId);

      if (existingIndex >= 0) {
        _items[existingIndex] = _items[existingIndex].copyWith(
          quantity: _items[existingIndex].quantity + quantity,
        );
      } else {
        final cartItem = CartItem.fromFirebaseDoc(firebaseDocId, data, quantity: quantity);
        _items.add(cartItem);
      }

      notifyListeners();
      _scheduleAutoSave(); // ✅ Auto-guardar
      return true;
    } catch (e) {
      debugPrint('Error al agregar producto desde Firebase: $e');
      return false;
    }
  }

  // Agregar producto manualmente
  void addItem({
    required String id,
    required String name,
    required double price,
    required String category,
    String? imageUrl,
    String? artisan,
    String? descripcion,
    String? uuid,
    int quantity = 1,
  }) {
    final existingIndex = _items.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        category: category,
        imageUrl: imageUrl,
        artisan: artisan,
        descripcion: descripcion,
        uuid: uuid,
        quantity: quantity,
      ));
    }

    notifyListeners();
    _scheduleAutoSave(); // ✅ Auto-guardar
  }

  // Remover un item específico del carrito
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    _scheduleAutoSave(); // ✅ Auto-guardar
  }

  // Actualizar cantidad de un item
  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }

    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
      _scheduleAutoSave(); // ✅ Auto-guardar
    }
  }

  // Incrementar cantidad de un item
  void incrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
      notifyListeners();
      _scheduleAutoSave(); // ✅ Auto-guardar
    }
  }

  // Decrementar cantidad de un item
  void decrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index] = _items[index].copyWith(
          quantity: _items[index].quantity - 1,
        );
        notifyListeners();
        _scheduleAutoSave(); // ✅ Auto-guardar
      } else {
        removeItem(id);
      }
    }
  }

  // Limpiar todo el carrito
  void clearCart() {
    _items.clear();
    notifyListeners();
    _scheduleAutoSave(); // ✅ Auto-guardar (carrito vacío)
  }

  // Obtener cantidad de un producto específico
  int getItemQuantity(String id) {
    final item = _items.firstWhere(
          (item) => item.id == id,
      orElse: () => CartItem(id: '', name: '', price: 0, category: ''),
    );
    return item.id.isEmpty ? 0 : item.quantity;
  }

  // Verificar si un producto está en el carrito
  bool containsItem(String id) {
    return _items.any((item) => item.id == id);
  }

  // Obtener items por categoría
  List<CartItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }

  // Obtener resumen del carrito
  Map<String, dynamic> getCartSummary() {
    final menItems = getItemsByCategory('men');
    final womenItems = getItemsByCategory('women');

    return {
      'totalItems': itemCount,
      'totalPrice': totalPrice,
      'menItems': menItems.length,
      'womenItems': womenItems.length,
      'menTotal': menItems.fold(0.0, (sum, item) => sum + item.totalPrice),
      'womenTotal': womenItems.fold(0.0, (sum, item) => sum + item.totalPrice),
    };
  }

  // Buscar productos en Firebase por categoría
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      final query = await _firestore
          .collection('productos')
          .where('categoria', isEqualTo: category)
          .where('activo', isEqualTo: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener productos por categoría: $e');
      return [];
    }
  }

  // Buscar producto específico por ID en Firebase
  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection('productos').doc(id).get();

      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener producto por ID: $e');
      return null;
    }
  }

  // ✅ MÉTODOS PÚBLICOS PARA CONTROL MANUAL (opcionales)

  // Guardar carrito manualmente
  Future<bool> saveCartToFirebase(String userId) async {
    try {
      final cartData = {
        'items': _items.map((item) => item.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalItems': itemCount,
        'totalPrice': totalPrice,
        'userId': userId,
      };

      await _firestore.collection('carritos').doc(userId).set(cartData);
      return true;
    } catch (e) {
      debugPrint('Error al guardar carrito manualmente: $e');
      return false;
    }
  }

  // Cargar carrito manualmente
  Future<bool> loadCartFromFirebase(String userId) async {
    try {
      final doc = await _firestore.collection('carritos').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final itemsList = data['items'] as List;

        _items.clear();
        for (var itemData in itemsList) {
          _items.add(CartItem.fromMap(itemData));
        }

        _hasLoadedFromFirebase = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al cargar carrito manualmente: $e');
      return false;
    }
  }

  // Limpiar recursos al destruir el servicio
  @override
  void dispose() {
    _authSubscription?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}