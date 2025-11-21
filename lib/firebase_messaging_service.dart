import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📥 [Background] Bildirim: ${message.notification?.title}");
}

Future<void> getFcmToken() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    final fcmToken = await messaging.getToken();
    print('📱 FCM Token: $fcmToken');

    if (fcmToken != null) {
      await sendTokenToBackend(fcmToken);
    }
  } else {
    print('🚫 Bildirim izinleri verilmedi.');
  }
}

Future<void> sendTokenToBackend(String fcmToken) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final loginToken = prefs.getString('token');

    print('🔍 Login Token: $loginToken');
    print('🔍 FCM Token: $fcmToken');

    if (loginToken == null || loginToken.isEmpty) {
      print('⚠️ Login token bulunamadı veya boş, token gönderilemiyor.');
      return;
    }

    final response = await http.post(
      Uri.parse('https://mobilapp.coffeerence.com.tr/api/save-token'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $loginToken',
      },
      body: json.encode({'token': fcmToken}),
    );

    print('🔍 Backend Response Status: ${response.statusCode}');
    print('🔍 Backend Response Headers: ${response.headers}');

    if (response.headers['content-type']?.contains('application/json') == true) {
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        print('✅ FCM token backend\'e başarıyla gönderildi.');
      }
      else {
        print('❌ FCM token gönderme başarısız: ${response.statusCode} - ${responseData['message'] ?? 'Bilinmeyen hata'}');
      }
    }
    else {
      print('❌ Backend JSON yerine HTML döndürüyor: ${response.body.substring(0, 100)}...');
      print('⚠️ API endpoint kontrol edilmeli: https://mobilapp.coffeerence.com.tr/api/save-token');
    }
  } catch (e) {
    print('❌ Token gönderilirken hata oluştu: $e');
  }
}

Future<void> setupFirebaseMessagingListeners(BuildContext context) async {

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 [Foreground] Bildirim: ${message.notification?.title}');
    if (message.notification != null) {
      final snackBar = SnackBar(
        content: Text(
          '${message.notification!.title ?? ''}\n${message.notification!.body ?? ''}',
        ),
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
        '📲 [Tapped] Bildirime tıklanarak uygulama açıldı: ${message.notification?.title}');
  });

  await getFcmToken();
}
