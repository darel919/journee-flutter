// ignore_for_file: unused_local_variable, avoid_print

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journee/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService extends StatefulWidget {
  const FCMService({super.key});

  @override
  State<FCMService> createState() => _FCMServiceState();
}

class _FCMServiceState extends State<FCMService> {
  final supabase = Supabase.instance.client;
  void _handleMessage(RemoteMessage message) {
    print(message);
      // if (message.data['type'] == 'chat') {
      //   print(message);
      //   // Navigator.pushNamed(context, '/chat',
      //   //   arguments: ChatArguments(message),
      //   // );
      // }
  }
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }
  void checkNotifPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
    NotifListener();
  }
  void NotifListener() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.toString()}');
    String? backMessage = message.notification!.body.toString();
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${message.data}, $backMessage'),
        elevation: 20.0,
      ),
    );

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  }
  void fcmService() async{
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    if (kIsWeb) {
      final fcmTokenWeb = await FirebaseMessaging.instance.getToken(vapidKey: "Lch8OOXbr4kHVQ9bEqgzWjNSB4ni1jeME-3eltniEN0");
      storeFCMTokenToDb(fcmTokenWeb!);
    } else {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      storeFCMTokenToDb(fcmToken!);
    }
    FirebaseMessaging.instance.onTokenRefresh
      .listen((fcmToken) {
        storeFCMTokenToDb(fcmToken);
      })
      .onError((err) {
        print('Cant retrieve token. Error: $err');
      });
}
  void storeFCMTokenToDb(String token) async {
    // if(token.isNotEmpty) {
      final session = supabase.auth.currentSession;
      final userMetadata = session?.user.userMetadata;
      try {
        await supabase.from('users')
        .update({
          'fcmToken': token
        })
        .match({ 'uuid': userMetadata!['provider_id'] });
      } catch (e) {
        SnackBar(
          content: Text('Error storing FCM ID: $e'),
          elevation: 20.0,
        );
        print("Error storing FCM Token ID. $e");
      }
    // }
  }

  @override
  void initState() {
    super.initState();
    checkNotifPermission();
    setupInteractedMessage();
    fcmService();
  }


  @override
  Widget build(BuildContext context) {
    return const HomePostView();
  }
}
