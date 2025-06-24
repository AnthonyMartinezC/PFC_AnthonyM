import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre Nosotros')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 20),
            _buildInfoCard(
              title: 'Nuestra Historia',
              content:
              'Austro Hats nació con el objetivo de llevar la tradición ecuatoriana al mundo moderno. Cada sombrero cuenta una historia de cultura, identidad y pasión artesanal. Nos enorgullece ser parte del legado andino.',
            ),
            _buildInfoCard(
              title: 'Misión',
              content:
              'Ofrecer productos auténticos, sostenibles y de alta calidad que reflejen nuestras raíces y promuevan el trabajo justo con comunidades locales.',
            ),
            _buildInfoCard(
              title: 'Visión',
              content:
              'Ser la marca de referencia en sombreros artesanales a nivel global, combinando tradición, innovación y diseño contemporáneo.',
            ),
            _buildInfoCard(
              title: 'Compromiso Sostenible',
              content:
              'Nuestros materiales provienen de fuentes responsables. Cada paso del proceso de producción respeta el medio ambiente y apoya a los artesanos ecuatorianos.',
            ),
            const SizedBox(height: 30),
            const Text(
              'Gracias por apoyar el arte ecuatoriano 💛',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            'https://media.istockphoto.com/id/1418628408/es/vector/colores-de-fondo-degradados-borrosos-abstractos-con-efecto-din%C3%A1mico.jpg?s=612x612&w=0&k=20&c=pU392MZOmgoqhiYRY0XFQCsnUIjdLAaS5gKnXw2D0yY=',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: 200,
            color: Colors.black.withOpacity(0.5),
            alignment: Alignment.center,
            child: const Text(
              'AUSTRO HATS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
