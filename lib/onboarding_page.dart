import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _orbController;
  late AnimationController _pulseController;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: FontAwesomeIcons.shieldVirus,
      title: 'Welcome to',
      highlight: 'SkinTermo AI',
      description:
          'Your personal AI-powered skin health companion. Advanced dermatology insights right at your fingertips.',
      gradientColors: [const Color(0xFF6C63FF), const Color(0xFF00D2FF)],
      featureIcon1: FontAwesomeIcons.wandMagicSparkles,
      feature1: 'AI-Powered Analysis',
      featureIcon2: FontAwesomeIcons.shieldHalved,
      feature2: 'Privacy First',
      featureIcon3: FontAwesomeIcons.clock,
      feature3: 'Instant Results',
    ),
    _OnboardingSlide(
      icon: FontAwesomeIcons.camera,
      title: 'AI-Powered',
      highlight: 'Skin Analysis',
      description:
          'Simply capture or upload a photo of your skin concern. Our advanced AI analyzes it instantly and provides detailed insights.',
      gradientColors: [const Color(0xFF9D4EDD), const Color(0xFF6C63FF)],
      featureIcon1: FontAwesomeIcons.camera,
      feature1: 'Camera Scan',
      featureIcon2: FontAwesomeIcons.images,
      feature2: 'Gallery Upload',
      featureIcon3: FontAwesomeIcons.microchip,
      feature3: 'On-Device AI',
    ),
    _OnboardingSlide(
      icon: FontAwesomeIcons.commentMedical,
      title: 'Healthcare',
      highlight: 'AI Assistant',
      description:
          'Chat with our specialized healthcare AI model for precise medical guidance, symptom explanations, and skin care recommendations.',
      gradientColors: [const Color(0xFF00D2FF), const Color(0xFF00E676)],
      featureIcon1: FontAwesomeIcons.comments,
      feature1: 'Smart Chat',
      featureIcon2: FontAwesomeIcons.stethoscope,
      feature2: 'Medical Insights',
      featureIcon3: FontAwesomeIcons.lightbulb,
      feature3: 'Care Tips',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _orbController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background orbs
          _buildAnimatedBackground(),
          // Page content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index], index);
                  },
                ),
              ),
              // Bottom section
              _buildBottomSection(),
            ],
          ),
          // Skip button
          if (_currentPage < _slides.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top-right orb
            Positioned(
              top: -100 + (math.sin(_orbController.value * 2 * math.pi) * 30),
              right: -80 + (math.cos(_orbController.value * 2 * math.pi) * 20),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _slides[_currentPage].gradientColors[0].withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom-left orb
            Positioned(
              bottom: 50 + (math.cos(_orbController.value * 2 * math.pi) * 25),
              left: -120 + (math.sin(_orbController.value * 2 * math.pi) * 15),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _slides[_currentPage].gradientColors[1].withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Center accent orb
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: MediaQuery.of(context).size.width * 0.3,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _slides[_currentPage].gradientColors[0].withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlide(_OnboardingSlide slide, int index) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Animated icon container
            FadeInDown(
              duration: const Duration(milliseconds: 700),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (_pulseController.value * 8),
                    height: 120 + (_pulseController.value * 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: slide.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: slide.gradientColors[0].withOpacity(
                            0.3 + _pulseController.value * 0.15,
                          ),
                          blurRadius: 40 + (_pulseController.value * 10),
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Icon(slide.icon, color: Colors.white, size: 48),
                  );
                },
              ),
            ),
            const SizedBox(height: 48),
            // Title
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 700),
              child: Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.2,
                ),
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 700),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: slide.gradientColors,
                  ).createShader(bounds);
                },
                child: Text(
                  slide.highlight,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Description
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 700),
              child: Text(
                slide.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.55),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Feature pills
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 700),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeaturePill(
                    slide.featureIcon1,
                    slide.feature1,
                    slide.gradientColors[0],
                  ),
                  const SizedBox(width: 10),
                  _buildFeaturePill(
                    slide.featureIcon2,
                    slide.feature2,
                    slide.gradientColors[1],
                  ),
                  const SizedBox(width: 10),
                  _buildFeaturePill(
                    slide.featureIcon3,
                    slide.feature3,
                    slide.gradientColors[0].withOpacity(0.8),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final isLastPage = _currentPage == _slides.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
        child: Column(
          children: [
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: _currentPage == index
                        ? LinearGradient(
                            colors: _slides[_currentPage].gradientColors,
                          )
                        : null,
                    color: _currentPage == index
                        ? null
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Action button
            SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isLastPage
                    ? ElevatedButton(
                        key: const ValueKey('start'),
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor:
                              _slides[_currentPage].gradientColors[0],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton(
                        key: const ValueKey('next'),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide(
                            color: _slides[_currentPage].gradientColors[0]
                                .withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: _slides[_currentPage].gradientColors[0],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _slides[_currentPage].gradientColors[0],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String highlight;
  final String description;
  final List<Color> gradientColors;
  final IconData featureIcon1;
  final String feature1;
  final IconData featureIcon2;
  final String feature2;
  final IconData featureIcon3;
  final String feature3;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.highlight,
    required this.description,
    required this.gradientColors,
    required this.featureIcon1,
    required this.feature1,
    required this.featureIcon2,
    required this.feature2,
    required this.featureIcon3,
    required this.feature3,
  });
}
