import 'dart:async';
import 'package:flutter/material.dart';

class BackgroundCarousel extends StatefulWidget {
  const BackgroundCarousel({super.key});

  @override
  State<BackgroundCarousel> createState() => _BackgroundCarouselState();
}

class _BackgroundCarouselState extends State<BackgroundCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _current = 0;

  final Color brandBlack = Colors.black;

  final List<String> _images = [
    'assets/login_bg.png',
    'assets/welcome_bg.jpg',
    'assets/welcome_bg_01.jpg',
    'assets/welcome_bg_02.jpg',
    'assets/welcome_bg_03.jpg',
    'assets/welcome_bg_04.jpg',
    'assets/welcome_bg_05.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;

      _current = (_current + 1) % _images.length;
      _controller.animateToPage(
        _current,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        /// 🔹 IMAGENS
        PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _images.length,
          itemBuilder: (_, index) {
            return Image.asset(
              _images[index],
              fit: BoxFit.cover,
            );
          },
        ),

        /// 🔹 GRADIENTE
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                brandBlack.withValues(alpha: 0.7),
                brandBlack.withValues(alpha: 0.3),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ],
    );
  }
}
