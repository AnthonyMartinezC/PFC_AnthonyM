import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRVerifyPage extends StatelessWidget {
  const QRVerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar QR')),
      body: MobileScanner(
        controller: MobileScannerController(
          facing: CameraFacing.back,
        ),
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? value = barcode.rawValue;
            if (value != null) {
              debugPrint('Código QR detectado: $value');
              // Aquí podrías verificar en Firebase, por ejemplo:
              // verificarSombrero(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Código: $value')),
              );
            }
          }
        },
      ),
    );
  }
}