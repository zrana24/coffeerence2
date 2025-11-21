import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      if (loggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {}
    }
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image/splash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(flex: 2, child: Container()),
              Text(
                "Hayat Kötü Kahve İçmek\nİçin Çok Kısa",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isPortrait
                      ? screenSize.width * 0.065
                      : screenSize.height * 0.065,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(blurRadius: 10.0, color: Colors.black54),
                  ],
                ),
              ),
              Expanded(flex: 3, child: Container()),
              Padding(
                padding: EdgeInsets.only(
                  bottom: screenSize.height * 0.05,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: screenSize.width * 0.5,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D4C41),
                          padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _navigateToHome,
                        child: Text(
                          "Hadi Başlayalım",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isPortrait
                                ? screenSize.width * 0.045
                                : screenSize.height * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: screenSize.height * 0.02),
                      child: Text(
                        "Uzunsoft.com tarafından geliştirilmiştir.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenSize.width * 0.025,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}