import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../firebase_messaging_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setupFirebaseMessagingListeners(context);
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (loggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://mobilapp.coffeerence.com.tr/api/login_procedures/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('email', emailController.text);
        await prefs.setString('password', passwordController.text);

        await getFcmToken();

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }

        if (responseData['1'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['1']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        String errorMessage = responseData['1'] ?? responseData['message'] ?? 'Giriş başarısız';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sunucuyla bağlantı kurulamadı'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _responsiveFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) return 14.0;
    if (screenWidth < 600) return 15.0;
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/');
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: screenHeight,
              child: Stack(
                children: [
                  SizedBox(
                    height: screenHeight * 0.30,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/image/login.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.10,
                    left: isSmallScreen ? 20.0 : 40.0,
                    right: isSmallScreen ? 20.0 : 40.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giriş Yap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 24.0 : 28.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giriş yapmak için e-posta adresini ve şifreni gir.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.22,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20.0 : 40.0,
                        vertical: 20.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.brown[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(35),
                          topRight: Radius.circular(35),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 15),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'E-posta Adresi',
                                        style: TextStyle(
                                          color: Color(0xFF424242),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Lütfen e-posta adresinizi girin';
                                        }
                                        if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(value)) {
                                          return 'Geçersiz e-posta formatı';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'E-posta adresi girin',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Şifre',
                                        style: TextStyle(
                                          color: Color(0xFF424242),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: !isPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Lütfen şifrenizi girin';
                                        }
                                        if (value.length < 6) {
                                          return 'Şifre en az 6 karakter olmalı';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Şifre girin',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off),
                                          onPressed: () {
                                            setState(() {
                                              isPasswordVisible = !isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/forgotPassword');
                                        },
                                        child: Text(
                                          'Şifremi Unuttum?',
                                          style: TextStyle(
                                            color: Colors.brown,
                                            fontWeight: FontWeight.bold,
                                            fontSize: _responsiveFontSize(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.brown[700],
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: _isLoading ? null : _loginUser,
                                        child: _isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text(
                                          'Giriş Yap',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.05),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                bottom: bottomPadding + (screenHeight * 0.08),
                              ),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(context, '/register');
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Mevcut hesabın yok mu? ',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: _responsiveFontSize(context),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Kayıt Ol',
                                          style: TextStyle(
                                            color: Colors.brown,
                                            fontWeight: FontWeight.bold,
                                            fontSize: _responsiveFontSize(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
