import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _sendResetPasswordEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta adresinizi giriniz';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final random = Random();
      final verificationCode = (100000 + random.nextInt(900000)).toString();

      print("Generated Verification Code: $verificationCode");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://mobilapp.coffeerence.com.tr/api/login_procedures/password_verification_code'),
      );

      request.fields['mail'] = email;
      request.fields['kod'] = verificationCode;

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = json.decode(responseBody);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationScreen(
                  email: email,
                  verificationCode: verificationCode,
                ),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = responseData['message'] ?? 'Kod gönderilemedi. Lütfen daha sonra tekrar deneyin.';
          });
        }
      }
      else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'HTTP hatası: ${response.statusCode}';
        });
      }
    }
    catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: ${e.toString()}';
      });
    }
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: screenSize.height,
            child: Stack(
              children: [
                // Top image section
                SizedBox(
                  height: screenSize.height * 0.35,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/image/login.png',
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Positioned(
                  top: screenSize.height * 0.15,
                  left: isSmallScreen ? 20.0 : 40.0,
                  right: isSmallScreen ? 20.0 : 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Şifremi Unuttum',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 24.0 : 28.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Şifreni sıfırlamak için kayıt olduğun e-posta adresini gir.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: screenSize.height * 0.27,
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
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Email field
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
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'user@gmail.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),

                        if (_successMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),

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
                            onPressed:
                            _isLoading ? null : _sendResetPasswordEmail,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Gönder',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}