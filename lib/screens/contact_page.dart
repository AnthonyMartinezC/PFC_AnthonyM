import 'package:flutter/material.dart';
import 'dart:math';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage>
    with SingleTickerProviderStateMixin {
  bool _isFront = true;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: 300,
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacto')),
      body: Center(
        child: GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final isFront = _animation.value < (pi / 2);
              final angle = isFront ? _animation.value : _animation.value - pi;

              return Transform(
                transform: Matrix4.rotationY(angle),
                alignment: Alignment.center,
                child: isFront
                    ? _buildCard(child: _frontContent())
                    : Transform(
                  transform: Matrix4.rotationY(pi),
                  alignment: Alignment.center,
                  child: _buildCard(child: _backContent()),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _frontContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text('Contáctanos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text('📍 Quito, Ecuador'),
        Text('📧 contacto@austrohats.com'),
        Text('📞 +593 99 123 4567'),
        Text('🌐 www.austrohats.com'),
        SizedBox(height: 12),
        Text('(Toca para girar)', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _backContent() {
    return Transform(
      transform: Matrix4.rotationY(pi),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            '¡Gracias por visitar nuestra web!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Tu apoyo hace posible que la cultura ecuatoriana siga viva en cada detalle. 💛',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text('(Toca para volver)', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

}
