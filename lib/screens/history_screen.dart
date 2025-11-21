import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String errorMessage = '';
  bool isTokenValid = false;

  @override
  void initState() {
    super.initState();
    _checkTokenAndFetchHistory();
  }

  Future<void> _checkTokenAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    setState(() => isTokenValid = true);
    _fetchOrderHistory(token);
  }

  Future<void> _fetchOrderHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://mobilapp.coffeerence.com.tr/api/coffeerence/order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          orders = responseData is List ? responseData : [];
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      } else {
        final errorResponse = json.decode(response.body);
        setState(() {
          errorMessage = errorResponse['message'] ?? 'Sipariş geçmişi alınamadı';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Sunucuyla bağlantı kurulamadı: $e';
        isLoading = false;
      });
    }
  }

  void _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('isLoggedIn');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isTokenValid) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Siparişlerim'),
        centerTitle: true,
        backgroundColor: Colors.brown,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.brown[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : orders.isEmpty
          ? const Center(child: Text('Henüz siparişiniz bulunmamaktadır'))
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.03,
          ),
          child: Column(
            children: orders.map((order) {
              return _buildOrderCard(
                order: order,
                screenWidth: screenWidth,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required dynamic order,
    required double screenWidth,
  }) {
    final isFree = order['free_coffe'] == "1";
    final date = _formatDate(order['created_at']);

    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.brown[300]!,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              size: screenWidth * 0.08,
              color: Colors.brown[600],
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş ${order['id']}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.035,
                vertical: screenWidth * 0.015,
              ),
              child: Text(
                isFree ? 'İkram' : 'Normal',
                style: TextStyle(
                  color: isFree ? Colors.green : Colors.orange[800],
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Bilinmeyen Tarih';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Bilinmeyen Tarih';
    }
  }
}