// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers, unused_element, unnecessary_new, unused_field, unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:journee/account.dart';
import 'package:journee/categories.dart';
import 'package:journee/home.dart';
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

Future<void> main() async {
  await dotenv.load(fileName: 'lib/.env');
  WidgetsFlutterBinding.ensureInitialized();
  var sbaseUrl = dotenv.env['supabaseUrl']!;
  var sbaseAnonKey = dotenv.env['supabaseAnonKey']!;
  await Supabase.initialize(
    url: sbaseUrl,
    anonKey: sbaseAnonKey,
    debug: false
  );
  // GoogleFonts.config.allowRuntimeFetching = false;
  runApp(MyApp());
  
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class NavigatorRoutes {
  final _router = GoRouter(
    redirect: (BuildContext context, GoRouterState state) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        return null;
      } else {
        return '/login';
      }   
    },
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/init',
    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => NavBar(child: child),
        routes: <RouteBase>[
          GoRoute(           
            path: '/',
            builder: (context, state) => HomePostView(),
            routes: <RouteBase>[
              GoRoute(
                path: 'post/:puid',
                builder: (context, state) => ViewPostRoute(
                  puid: state.pathParameters['puid']
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => EditDiary(
                      puid: state.pathParameters['puid']
                    ),
                  ),
                ]
              ),
              GoRoute(
                path: 'thread/:tuid',
                builder: (context, state) => ViewThreadsRoute(
                  tuid: state.pathParameters['tuid']
                ),
              ),
              GoRoute(
                path: 'category/:cuid',
                builder: (context, state) => CategoriesViewPage(
                  cuid: state.pathParameters['cuid']
                ),
              ),
              GoRoute(
                path: 'user/:uuid',
                builder: (context, state) => UserPageRoute(
                  uuid: state.pathParameters['uuid'], 
                ),
              ),
              GoRoute(
                path: 'create/diary',
                builder: (context, state) => const CreateDiaryPage(),
              ),
              GoRoute(
                path: 'search',
                builder: (context, state) => const SearchPage(),
              ),
              GoRoute(
                path: 'account',
                builder: (context, state) => const AccountPage(),
              ),
            ],
          ),
        ]
      ),   
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/init',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/update',
        builder: (context, state) => const UpdatePage(),
      ),
    ],
  );    
}

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
        textTheme: GoogleFonts.ralewayTextTheme(baseTheme.textTheme)
      );
  }
  final _appRouter = NavigatorRoutes();
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Journee',
      theme: _theme(Brightness.light),
      themeMode: ThemeMode.system, 
      darkTheme: _theme(Brightness.dark),
      // routerConfig: _router,
      routerConfig: _appRouter._router,
    );
  }
}

