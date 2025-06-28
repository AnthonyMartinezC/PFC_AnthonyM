import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class QRVerifyPage extends StatefulWidget {
  const QRVerifyPage({super.key});

  @override
  State<QRVerifyPage> createState() => _QRVerifyPageState();
}

class _QRVerifyPageState extends State<QRVerifyPage> {
  late MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    if (!AuthService.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Debes iniciar sesión para verificar productos', isError: true);
        Navigator.pop(context);
      });
    }
  }

  Future<void> _verifyScannedCode(String code) async {
    if (!AuthService.isAuthenticated) {
      _showSnackBar('Debes iniciar sesión para verificar productos', isError: true);
      return;
    }

    // Evitar verificaciones duplicadas del mismo código
    if (_lastScannedCode == code && _verificationResult != null) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _isScanning = false;
      _lastScannedCode = code;
      _verificationResult = null;
    });

    try {
      final result = await FirebaseService.verificarProductoPorUUID(code);

      setState(() {
        _verificationResult = result;
        _isVerifying = false;
      });

      if (result == null || result['encontrado'] == false) {
        _showSnackBar('❌ Este sombrero NO está registrado en nuestra base de datos', isError: true);
      } else if (result['esAutentico'] == true) {
        _showSnackBar('✅ Este sombrero está REGISTRADO y es auténtico');
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationResult = {
          'esAutentico': false,
          'mensaje': 'Error de conexión: $e',
          'encontrado': false,
        };
      });
      _showSnackBar('❌ Error de conexión: $e', isError: true);
    }
  }

  void _startNewScan() {
    setState(() {
      _isScanning = true;
      _verificationResult = null;
      _lastScannedCode = null;
    });
  }

  void _toggleTorch() async {
    await _scannerController.toggleTorch();
  }

  void _switchCamera() async {
    await _scannerController.switchCamera();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Widget _buildUserInfo() {
    final userInfo = AuthService.getUserInfo();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: userInfo['isAdmin'] ? Colors.purple.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            userInfo['isAdmin'] ? Icons.admin_panel_settings : Icons.person,
            color: userInfo['isAdmin'] ? Colors.purple.shade700 : Colors.blue.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            userInfo['isAdmin'] ? 'Admin' : 'Usuario',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: userInfo['isAdmin'] ? Colors.purple.shade700 : Colors.blue.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (!_isScanning || _isVerifying) return;

            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? value = barcode.rawValue;
              if (value != null && value.isNotEmpty) {
                _verifyScannedCode(value);
                break; // Solo procesar el primer código válido
              }
            }
          },
        ),

        // Overlay con marco de escaneo
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),

        // Controles del scanner
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUserInfo(),
              Row(
                children: [
                  IconButton(
                    onPressed: _toggleTorch,
                    icon: const Icon(Icons.flash_on),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(Icons.flip_camera_ios),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Instrucciones
        Positioned(
          bottom: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Apunta la cámara al código QR del sombrero',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Loading overlay
        if (_isVerifying)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Verificando autenticidad...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultView() {
    if (_verificationResult == null) return const SizedBox.shrink();

    final isAuthentic = _verificationResult!['esAutentico'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Resultado principal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isAuthentic ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAuthentic ? Colors.green.shade300 : Colors.red.shade300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isAuthentic ? Icons.verified : Icons.error,
                  size: 64,
                  color: isAuthentic ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(height: 16),
                Text(
                  isAuthentic ? 'PRODUCTO AUTÉNTICO' : 'PRODUCTO NO REGISTRADO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isAuthentic ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _verificationResult!['mensaje'] ?? 'Sin mensaje',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Información del producto si es auténtico
          if (isAuthentic && _verificationResult!['producto'] != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Sombrero',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Imagen del producto si existe
                  if (_verificationResult!['producto']['imagenUrl'] != null &&
                      _verificationResult!['producto']['imagenUrl'].toString().isNotEmpty) ...[
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _verificationResult!['producto']['imagenUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildInfoRow('Nombre:', _verificationResult!['producto']['nombre']),
                  _buildInfoRow('Artesano:', _verificationResult!['producto']['artesano']),

                  // Solo mostrar precio y detalles adicionales si es admin
                  if (AuthService.isAdmin) ...[
                    _buildInfoRow('Precio:', '\$${_verificationResult!['producto']['precio']}'),
                    if (_verificationResult!['producto']['descripcion'] != null &&
                        _verificationResult!['producto']['descripcion'].toString().isNotEmpty)
                      _buildInfoRow('Descripción:', _verificationResult!['producto']['descripcion']),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Botón para escanear de nuevo
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startNewScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear Otro Código'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'No disponible',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar QR'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isScanning
          ? _buildScannerView()
          : SingleChildScrollView(
        child: _buildResultView(),
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}