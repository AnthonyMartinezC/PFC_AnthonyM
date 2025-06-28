import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/firebase_service.dart';

class QRGeneratorPage extends StatefulWidget {
  const QRGeneratorPage({super.key});

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _artisanController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _currentUUID = '';
  String _qrData = '';
  bool _isLoading = false;
  bool _isNewProduct = true; // Toggle entre crear nuevo o buscar existente
  Map<String, dynamic>? _foundProduct;

  // Crear nuevo producto en Firebase y generar QR
  Future<void> _createNewProductWithQR() async {
    final productName = _productNameController.text.trim();
    final artisan = _artisanController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();

    if (productName.isEmpty || artisan.isEmpty || priceText.isEmpty) {
      _showSnackBar('Por favor completa todos los campos obligatorios', isError: true);
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showSnackBar('Por favor ingresa un precio válido', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uuid = await FirebaseService.crearProductoConUUID(
        nombre: productName,
        categoria: 'sombreros', // Puedes hacer esto dinámico si necesitas
        artesano: artisan,
        precio: price,
        descripcion: description,
      );

      setState(() {
        _currentUUID = uuid;
        _qrData = uuid;
        _isLoading = false;
      });

      _showSnackBar('✅ Producto creado y QR generado exitosamente');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('❌ Error al crear producto: $e', isError: true);
    }
  }

  // Buscar producto existente y generar QR
  Future<void> _findExistingProductAndGenerateQR() async {
    final productName = _productNameController.text.trim();

    if (productName.isEmpty) {
      _showSnackBar('Por favor ingresa el nombre del producto', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final product = await FirebaseService.buscarProductoPorNombre(productName);

      if (product != null && product['uuid'] != null) {
        setState(() {
          _foundProduct = product;
          _currentUUID = product['uuid'];
          _qrData = product['uuid'];
          _isLoading = false;

          // Llenar los campos con la info del producto encontrado
          _artisanController.text = product['artesano'] ?? '';
          _priceController.text = product['precio']?.toString() ?? '';
          _descriptionController.text = product['descripcion'] ?? '';
        });

        _showSnackBar('✅ Producto encontrado y QR generado');
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('❌ Producto no encontrado o sin UUID', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('❌ Error al buscar producto: $e', isError: true);
    }
  }

  // Generar UUIDs para productos existentes sin UUID
  Future<void> _generateUUIDsForExistingProducts() async {
    setState(() => _isLoading = true);

    try {
      final count = await FirebaseService.generarUUIDsParaProductosExistentes();
      setState(() => _isLoading = false);
      _showSnackBar('✅ Se generaron UUIDs para $count productos');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('❌ Error: $e', isError: true);
    }
  }

  void _copyUUID() {
    if (_currentUUID.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _currentUUID));
      _showSnackBar('UUID copiado al portapapeles');
    }
  }

  void _clearForm() {
    setState(() {
      _productNameController.clear();
      _artisanController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _currentUUID = '';
      _qrData = '';
      _foundProduct = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador QR - Sistema de Autenticidad'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _generateUUIDsForExistingProducts,
            icon: const Icon(Icons.update),
            tooltip: 'Generar UUIDs para productos existentes',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle entre nuevo producto y buscar existente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Crear Nuevo'),
                        value: true,
                        groupValue: _isNewProduct,
                        onChanged: (value) {
                          setState(() {
                            _isNewProduct = value!;
                            _clearForm();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Buscar Existente'),
                        value: false,
                        groupValue: _isNewProduct,
                        onChanged: (value) {
                          setState(() {
                            _isNewProduct = value!;
                            _clearForm();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isNewProduct ? 'Crear Nuevo Producto' : 'Buscar Producto Existente',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            TextField(
                              controller: _productNameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Nombre del Sombrero *',
                                hintText: 'Ej. Sombrero Panamá Premium',
                              ),
                            ),

                            if (_isNewProduct) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _artisanController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Artesano *',
                                  hintText: 'Ej. Juan Pérez',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Precio *',
                                  hintText: 'Ej. 150.00',
                                  prefixText: '\$ ',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Descripción (opcional)',
                                  hintText: 'Detalles del sombrero...',
                                ),
                                maxLines: 3,
                              ),
                            ] else if (_foundProduct != null) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _artisanController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Artesano',
                                ),
                                readOnly: true,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Precio',
                                  prefixText: '\$ ',
                                ),
                                readOnly: true,
                              ),
                            ],

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : (_isNewProduct
                                        ? _createNewProductWithQR
                                        : _findExistingProductAndGenerateQR),
                                    icon: _isLoading
                                        ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2)
                                    )
                                        : const Icon(Icons.qr_code),
                                    label: Text(_isNewProduct ? 'Crear y Generar QR' : 'Buscar y Generar QR'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _clearForm,
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Limpiar formulario',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // QR Code Display
                    if (_qrData.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Código QR de Autenticidad',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: QrImageView(
                                  data: _qrData,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Token de Autenticidad:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            _currentUUID,
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _copyUUID,
                                      icon: const Icon(Icons.copy, size: 18),
                                      tooltip: 'Copiar UUID',
                                    ),
                                  ],
                                ),
                              ),
                              if (_foundProduct != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.verified, color: Colors.green.shade600, size: 16),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Producto encontrado en base de datos',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _artisanController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}