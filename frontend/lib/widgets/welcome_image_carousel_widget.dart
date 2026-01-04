import 'dart:async';
import 'package:flutter/material.dart';

class WelcomeImageCarousel extends StatefulWidget {
  const WelcomeImageCarousel({super.key});

  @override
  State<WelcomeImageCarousel> createState() => _WelcomeImageCarouselState();
}

class _WelcomeImageCarouselState extends State<WelcomeImageCarousel> {
  final PageController _pageController = PageController();
  final Duration _interval = const Duration(seconds: 4);

  int _currentPage = 0;

  final List<String> _images = [
    'assets/login_bg.png',
    'assets/welcome_bg.jpg',
    'assets/welcome_bg_01.jpg',
    'assets/welcome_bg_02.jpg',
    'assets/welcome_bg_03.jpg',
    'assets/welcome_bg_04.jpg',
    'assets/welcome_bg_05.jpg',
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(_interval, (_) {
      if (!_pageController.hasClients) return;

      _currentPage = (_currentPage + 1) % _images.length;

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _images.length,
          onPageChanged: (index) => _currentPage = index,
          itemBuilder: (context, index) {
            return Image.asset(
              _images[index],
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}
