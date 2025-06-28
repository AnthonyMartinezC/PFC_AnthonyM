import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class QRVerificationPage extends StatefulWidget {
  const QRVerificationPage({super.key});

    @override
    State<QRVerificationPage> createState() => _QRVerificationPageState();
}

class _QRVerificationPageState extends State<QRVerificationPage> {
    final TextEditingController _uuidController = TextEditingController();
    bool _isLoading = false;
    Map<String, dynamic>? _verificationResult;

    @override
    void initState() {
        super.initState();
        _checkAuthStatus();
    }

    void _checkAuthStatus() {
        if (!AuthService.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showSnackBar('Debes iniciar sesión para verificar productos', isError: true);
      });
        }
    }

    Future<void> _verifyProduct() async {
        if (!AuthService.isAuthenticated) {
            _showSnackBar('Debes iniciar sesión para verificar productos', isError: true);
            return;
        }

        final uuid = _uuidController.text.trim();

        if (uuid.isEmpty) {
            _showSnackBar('Por favor ingresa o escanea un código UUID', isError: true);
            return;
        }

        setState(() {
            _isLoading = true;
            _verificationResult = null;
        });

        try {
            final result = await FirebaseService.verificarProductoPorUUID(uuid);

            setState(() {
                _verificationResult = result;
                _isLoading = false;
            });

            if (result == null || result['encontrado'] == false) {
                _showSnackBar('❌ Este sombrero NO está registrado en nuestra base de datos', isError: true);
            } else if (result['esAutentico'] == true) {
                _showSnackBar('✅ Este sombrero está REGISTRADO y es auténtico');
            } else {
                _showSnackBar('❌ Error en la verificación', isError: true);
            }
        } catch (e) {
            setState(() {
                _isLoading = false;
                _verificationResult = {
                        'esAutentico': false,
                        'mensaje': 'Error de conexión: $e',
                        'encontrado': false,
        };
            });
            _showSnackBar('❌ Error de conexión: $e', isError: true);
        }
    }

    Future<void> _scanQRCode() async {
        // Aquí integrarías un scanner QR como qr_code_scanner
        // Por ahora simulo que el usuario pegó el código
        _showSnackBar('Funcionalidad de escáner QR - Integrar con qr_code_scanner package');
    }

    void _pasteFromClipboard() async {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        if (clipboardData != null && clipboardData.text != null) {
            _uuidController.text = clipboardData.text!;
        }
    }

    void _clearForm() {
        setState(() {
            _uuidController.clear();
            _verificationResult = null;
        });
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

        if (!userInfo['isAuthenticated']) {
            return Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                    children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Expanded(
                    child: Text(
                    'Debes iniciar sesión para verificar productos',
                    style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
        }

        return Card(
                color: userInfo['isAdmin'] ? Colors.purple.shade50 : Colors.blue.shade50,
                child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                children: [
        Icon(
                userInfo['isAdmin'] ? Icons.admin_panel_settings : Icons.person,
                color: userInfo['isAdmin'] ? Colors.purple.shade700 : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
        Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        Text(
                userInfo['isAdmin'] ? 'Administrador' : 'Usuario',
                style: TextStyle(
                fontWeight: FontWeight.bold,
                color: userInfo['isAdmin'] ? Colors.purple.shade700 : Colors.blue.shade700,
                    ),
                  ),
        Text(
                userInfo['email'] ?? 'Usuario',
                style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
                appBar: AppBar(
                title: const Text('Verificación de Autenticidad'),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
      ),
        body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
        // Info del usuario
        _buildUserInfo(),

            const SizedBox(height: 16),

        // Instrucciones
        Card(
                color: Colors.blue.shade50,
                child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                children: [
        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 32),
                    const SizedBox(height: 8),
        Text(
                'Verificación de Autenticidad',
                style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                'Escanea el código QR del sombrero o ingresa manualmente el código UUID para verificar su autenticidad.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

        // Input del UUID
        Card(
                child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text(
                'Código de Verificación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
        TextField(
                controller: _uuidController,
                decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'UUID del Producto',
                hintText: 'Ej. 123e4567-e89b-12d3-a456-426614174000',
                      ),
        style: const TextStyle(fontFamily: 'monospace'),
        enabled: AuthService.isAuthenticated,
                    ),
                    const SizedBox(height: 12),
        Row(
                children: [
        Expanded(
                child: ElevatedButton.icon(
                onPressed: AuthService.isAuthenticated ? _scanQRCode : null,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear QR'),
                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
        IconButton(
                onPressed: AuthService.isAuthenticated ? _pasteFromClipboard : null,
                icon: const Icon(Icons.paste),
                tooltip: 'Pegar desde portapapeles',
                        ),
        IconButton(
                onPressed: _clearForm,
                icon: const Icon(Icons.clear),
                tooltip: 'Limpiar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
        SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                onPressed: (_isLoading || !AuthService.isAuthenticated) ? null : _verifyProduct,
                icon: _isLoading
                ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)
                              )
                            : const Icon(Icons.verified_user),
                label: const Text('Verificar Autenticidad'),
                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

        // Resultado de la verificación
        if (_verificationResult != null) ...[
        Expanded(
                child: Card(
                color: _verificationResult!['esAutentico'] == true
                ? Colors.green.shade50
                : Colors.red.shade50,
                child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                child: Column(
                children: [
        Icon(
                _verificationResult!['esAutentico'] == true
                ? Icons.verified
                : Icons.error,
                size: 48,
                color: _verificationResult!['esAutentico'] == true
                ? Colors.green.shade700
                : Colors.red.shade700,
                          ),
                          const SizedBox(height: 16),
        Text(
                _verificationResult!['esAutentico'] == true
                ? 'PRODUCTO AUTÉNTICO'
                : 'PRODUCTO NO REGISTRADO',
                style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _verificationResult!['esAutentico'] == true
                ? Colors.green.shade700
                : Colors.red.shade700,
                            ),
        textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
        Text(
                _verificationResult!['mensaje'] ?? 'Sin mensaje',
                style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
                          ),

        // Mostrar información del producto si es auténtico
        if (_verificationResult!['esAutentico'] == true &&
                _verificationResult!['producto'] != null) ...[
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text(
                'Información del Sombrero',
                style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

        // Imagen del producto si existe
        if (_verificationResult!['producto']['imagenUrl'] != null &&
                _verificationResult!['producto']['imagenUrl'].toString().isNotEmpty) ...[
        Container(
                height: 150,
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
                    size: 50,
                    color: Colors.grey,
                                        ),
                                      );
        },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

        _buildInfoRow('Nombre:', _verificationResult!['producto']['nombre']),
        _buildInfoRow('Artesano:', _verificationResult!['producto']['artesano']),

        // Solo mostrar precio y detalles adicionales si es admin
        if (AuthService.isAdmin) ...[
        _buildInfoRow('Precio:', '\${_verificationResult!['producto']['precio']}'),
        if (_verificationResult!['producto']['descripcion'] != null &&
                _verificationResult!['producto']['descripcion'].toString().isNotEmpty)
        _buildInfoRow('Descripción:', _verificationResult!['producto']['descripcion']),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                child: Text(
                'Ingresa un código UUID para verificar',
                style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    }

    Widget _buildInfoRow(String label, dynamic value) {
        return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
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
    void dispose() {
        _uuidController.dispose();
        super.dispose();
    }
}