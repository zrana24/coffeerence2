import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String verificationCode;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.verificationCode,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _remainingSeconds = 300;
  late Timer _timer;
  bool _isSubmitEnabled = true;
  bool _isResending = false;
  bool _isVerifying = false;
  String? _resendErrorMessage;
  String? _verifyErrorMessage;
  late String _currentVerificationCode;

  @override
  void initState() {
    super.initState();
    _currentVerificationCode = widget.verificationCode;
    _startTimer();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    });
    debugPrint("Received Verification Code: ${widget.verificationCode}");
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _isSubmitEnabled = false;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _resendErrorMessage = null;
    });

    try {
      final random = Random();
      final newCode = (100000 + random.nextInt(900000)).toString();
      debugPrint("Resent Verification Code: $newCode");

      setState(() {
        _currentVerificationCode = newCode;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://mobilapp.coffeerence.com.tr/api/login_procedures/password_verification_code'),
      );

      request.fields['mail'] = widget.email;
      request.fields['kod'] = newCode;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = json.decode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        setState(() {
          _remainingSeconds = 300;
          _isSubmitEnabled = true;
          for (var controller in _controllers) {
            controller.clear();
          }
          FocusScope.of(context).requestFocus(_focusNodes[0]);
        });
        _startTimer();
      }
      else {
        final errorMessage = responseData['message']?.isNotEmpty == true
            ? responseData['message']
            : 'Kod gönderilemedi. Lütfen daha sonra tekrar deneyin.';

        setState(() {
          _resendErrorMessage = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _resendErrorMessage = 'Bağlantı hatası: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  Future<void> _submitVerification() async {
    if (!_isSubmitEnabled || _isVerifying) return;

    final enteredCode = _controllers.map((c) => c.text).join();
    if (enteredCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen 6 haneli kodu giriniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _verifyErrorMessage = null;
    });

    try {
      if (enteredCode == _currentVerificationCode) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'https://mobilapp.coffeerence.com.tr/api/login_procedures/passwordreflesh'),
        );

        request.fields['mail'] = widget.email;

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        if (response.statusCode == 200 && responseData['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Şifre sıfırlama başarılı. Yeni şifreniz e-posta ile gönderildi.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          final errorMessage = responseData['message']?.isNotEmpty == true
              ? responseData['message']
              : 'Şifre sıfırlama başarısız. Lütfen tekrar deneyin.';

          setState(() {
            _verifyErrorMessage = errorMessage;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama kodu hatalı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _verifyErrorMessage = 'Bağlantı hatası: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/forgotPassword');
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            height: screenSize.height,
            child: Stack(
              children: [
                SizedBox(
                  height: screenSize.height * 0.35,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/image/login.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: screenSize.height * 0.10,
                  left: isSmallScreen ? 20.0 : 40.0,
                  right: isSmallScreen ? 20.0 : 40.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesap Doğrulama',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 24.0 : 28.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hesabını doğrulamak için ${widget.email} adresine gelen doğrulama kodunu gir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      vertical: 10.0,
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
                        const SizedBox(height: 10),
                        const SizedBox(height: 15),
                        Text(
                          'Doğrulama Kodu',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18.0 : 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (index) => Container(
                              width: isSmallScreen ? 40.0 : 50.0,
                              height: isSmallScreen ? 60.0 : 70.0,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                  onChanged: (value) =>
                                      _onChanged(value, index),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_resendErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _resendErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        // Verification error message
                        if (_verifyErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _verifyErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isSubmitEnabled && !_isVerifying)
                                ? _submitVerification
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (_isSubmitEnabled && !_isVerifying)
                                      ? Colors.brown[700]
                                      : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isVerifying
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
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
                        const SizedBox(height: 24),

                        Center(
                          child: Column(
                            children: [
                              Text(
                                '$_remainingSeconds saniye kaldı',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: isSmallScreen ? 14.0 : 16.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: !_isResending ? _resendCode : null,
                                child: _isResending
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                        'Tekrar Gönder',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.brown,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
