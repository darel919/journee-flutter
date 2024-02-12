// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  await dotenv.load(fileName: 'lib/.env');
  WidgetsFlutterBinding.ensureInitialized();
  var sbaseUrl = dotenv.env['supabaseUrl']!;
  var sbaseAnonKey = dotenv.env['supabaseAnonKey']!;

  await Supabase.initialize(
    url: sbaseUrl,
    anonKey: sbaseAnonKey,
  );

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journee',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 0, 2, 123)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    final _future = Supabase.instance.client
      .from('posts')
      .select('''*, users(*), threads ( * ), categories ( * )''')
      .order('created_at',  ascending: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
            final posts = snapshot.data!;
            
            return ListView.builder(
            itemCount: posts.length,
            itemBuilder: ((context, index) {
              final post = posts[index];
              final user = post['users'];
              DateTime myDateTime = DateTime.parse(post['created_at']);
              return ListTile(
                contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                isThreeLine: true,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(48.0),
                  child: Image.network(user['avatar_url']
                  )
                ),
                title: Text(user['name'], style: TextStyle(fontSize: 16)),
                trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
                subtitle: Text(post['details'], maxLines: 1, style: TextStyle(fontSize: 12.5)),
              );
            }),
            );
        },
      )
    );
  }
}
