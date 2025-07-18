import 'package:flutter/material.dart';
import 'package:studyhub/features/login/login_screen.dart';

class IntroPages extends StatefulWidget {
  final VoidCallback? onDone;

  const IntroPages({super.key, this.onDone});

  @override
  _IntroPagesState createState() => _IntroPagesState();
}

class _IntroPagesState extends State<IntroPages> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_IntroPageData> pages = [
    _IntroPageData(
      title: "Organize Your Study Materials",
      description:
          "Keep all notes, PDFs, photos, and important questions in one place.",
      imagePath: "assets/logos/first.png",
    ),
    _IntroPageData(
      title: "Upload & Import Easily",
      description: "Take photos or import files securely inside the app.",
      imagePath: "assets/logos/third.png",
    ),
    _IntroPageData(
      title: "Share & Study Together",
      description: "Share files with classmates and study anywhere, anytime.",
      imagePath: "assets/logos/second.png",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget _buildPage(_IntroPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(page.imagePath, height: 220, fit: BoxFit.contain),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF7F8C8D),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: _currentIndex == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? const Color(0xFF2980B9)
                : const Color(0xFFBDC3C7),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildButtons() {
    if (_currentIndex == pages.length - 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2980B9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              "Get Started",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _navigateToLogin,
              child: const Text(
                "Skip",
                style: TextStyle(color: Color(0xFF2980B9), fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2980B9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (_, index) => _buildPage(pages[index]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: 24),
            _buildButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _IntroPageData {
  final String title;
  final String description;
  final String imagePath;

  _IntroPageData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
