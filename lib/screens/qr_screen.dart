import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  String result = 'QR kodunu taratmak için kamerayı hedefe yöneltin';
  bool isLoading = false;
  bool isSuccess = false;
  bool? freeCoffee;
  String? freeCoffeeCount;

  bool _isProcessing = false;
  bool _isCheckingLogin = true;
  bool _shouldStopScanning = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        _isCheckingLogin = false;
      });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _sendToApi(String qrData) async {
    if (_isProcessing || _shouldStopScanning) return;

    _isProcessing = true;

    setState(() {
      isLoading = true;
      isSuccess = false;
      freeCoffee = null;
      freeCoffeeCount = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          result = 'Oturum bulunamadı. Lütfen tekrar giriş yapın.';
          isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.post(
        Uri.parse('https://mobilapp.coffeerence.com.tr/api/coffeerence/add_coffee'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'qrcode': qrData}),
      );

      final responseData = json.decode(response.body);

      setState(() {
        isSuccess = responseData['success'] ?? false;
        freeCoffee = responseData['freecoffe'] ?? false;
        freeCoffeeCount = responseData['free_coffe_count']?.toString() ?? '';

        if (isSuccess) {
          result = responseData['message'] ?? 'QR kodu başarıyla işlendi';
        } else {
          result = responseData['message'] ?? 'QR kodu işlenirken hata oluştu';
        }
      });

      if (isSuccess) {
        _blockScanningForTwoMinutes();
        await Future.delayed(const Duration(seconds: 1));
        _navigateToHome();
      }
    } catch (e) {
      setState(() {
        result = 'Sunucu hatası: Lütfen tekrar deneyin';
      });
    } finally {
      setState(() {
        isLoading = false;
        _isProcessing = false;
      });
    }
  }

  void _blockScanningForTwoMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastScanTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _isScanningBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final lastScanTime = prefs.getInt('lastScanTime');

    if (lastScanTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    const twoMinutes = 2 * 60 * 1000;

    return (now - lastScanTime) < twoMinutes;
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<bool> _onWillPop() async {
    _navigateToHome();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLogin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("QR Okuyucu"),
          backgroundColor: Colors.brown,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _onWillPop(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () async {
                await cameraController.toggleTorch();
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
              },
            ),
          ],

        ),
        body: FutureBuilder<bool>(
          future: _isScanningBlocked(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final isBlocked = snapshot.data ?? false;

            if (isBlocked) {
              return _buildBlockedScreen();
            }

            return _buildScannerScreen();
          },
        ),
      ),
    );
  }

  Widget _buildScannerScreen() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final code = barcode.rawValue;
                if (code != null && !isLoading && !_isProcessing && !_shouldStopScanning) {
                  setState(() {
                    result = "İşleniyor: $code";
                  });
                  _sendToApi(code);
                }
              }
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: isSuccess
                ? Colors.green.withOpacity(0.1)
                : (isLoading ? Colors.grey.withOpacity(0.1) : Colors.white),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const CircularProgressIndicator()
                else if (isSuccess)
                  Column(
                    children: [
                      Text(
                        result,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (freeCoffeeCount != null && freeCoffeeCount!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Kalan hediye kahve hakkınız: $freeCoffeeCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Text(
                    result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 64, color: Colors.brown),
          SizedBox(height: 16),
          Text(
            'QR Tarama Geçici Olarak Devre Dışı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Son QR taramanızdan sonra 2 dakika\nbeklemeniz gerekmektedir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Ana sayfaya yönlendiriliyorsunuz...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
