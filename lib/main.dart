// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers, unused_element, unnecessary_new, unused_field, unrelated_type_equality_checks

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:journee/account.dart';
import 'package:journee/categories.dart';
import 'package:journee/fcm.dart';
import 'package:journee/login.dart';
import 'package:journee/modify.dart';
import 'package:journee/navbar.dart';
import 'package:journee/post.dart';
import 'package:journee/search.dart';
import 'package:journee/splash.dart';
import 'package:journee/threads.dart';
import 'package:journee/updater.dart';
import 'package:journee/user_posts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await dotenv.load(fileName: 'lib/.env');
  
  WidgetsFlutterBinding.ensureInitialized();
  // var sbaseUrl = dotenv.env['supabaseUrl']!;
  var sbaseUrl2 = dotenv.env['supabaseSelfHostUrl']!;
  var sbasekey2 = dotenv.env['supabaseSelfHostKey']!;
  // var sbaseAnonKey = dotenv.env['supabaseAnonKey']!;
  await Supabase.initialize(
    url: sbaseUrl2,
    anonKey: sbasekey2,
    debug: false
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
  
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}


final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();


class MyApp extends StatelessWidget {
  
  MyApp({super.key});
  ThemeData _theme(brightness1) {
    var baseTheme = ThemeData(brightness: brightness1);
    
    return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0x00001238), 
          brightness: brightness1
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.ralewayTextTheme(baseTheme.textTheme),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: brightness1 == Brightness.dark
          ? Colors.white // White text color for dark mode
          : Colors.black, // This sets the text color for TextButtons
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(style: TextButton.styleFrom(
            foregroundColor: brightness1 == Brightness.dark
          ? Colors.white // White text color for dark mode
          : Colors.black, // This sets the text color for TextButtons
          ),
        )
      );
  }
  final _router = GoRouter(
    redirect: (BuildContext context, GoRouterState state) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        return null;
      } 
      // print(session);
      else {
        return '/login';
      }   
    },
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/init',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => BottomNavBar(child: child),
        routes: [
          GoRoute(           
            path: '/',
            parentNavigatorKey: _shellNavigatorKey,
            builder: (context, state) => FCMService(),
            routes: [
              GoRoute(
                path: 'post/:puid',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ViewPostRoute(
                  puid: state.pathParameters['puid']
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => EditDiary(
                      puid: state.pathParameters['puid']
                    ),
                  ),
                ]
              ),
              GoRoute(
                path: 'thread/:tuid',
                parentNavigatorKey: _shellNavigatorKey,
                builder: (context, state) => ViewThreadsRoute(
                  tuid: state.pathParameters['tuid']
                ),
              ),
              GoRoute(
                path: 'category/:cuid',
                parentNavigatorKey: _shellNavigatorKey,
                builder: (context, state) => CategoriesViewPage(
                  cuid: state.pathParameters['cuid'],
                  home: false
                ),
              ),
              GoRoute(
                path: 'user/:uuid',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => UserPageRoute(
                  uuid: state.pathParameters['uuid'], 
                ),
              ),
              GoRoute(
                path: 'create/diary',
                parentNavigatorKey: _shellNavigatorKey,
                builder: (context, state) => const CreateDiaryPage(),
              ),
              GoRoute(
                path: 'search',
                parentNavigatorKey: _shellNavigatorKey,
                builder: (context, state) => const SearchPage(),
              ),
              GoRoute(
                path: 'account',
                parentNavigatorKey: _shellNavigatorKey,
                builder: (context, state) => const AccountPage(),
              ),
            ],
          ),
        ]
      ),   
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/init',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/update',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpdatePage(),
      ),
    ],
  );    
  
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Journee',
      theme: _theme(Brightness.light),
      themeMode: ThemeMode.system, 
      darkTheme: _theme(Brightness.dark),
      routerConfig: _router,
    );
  }
}

