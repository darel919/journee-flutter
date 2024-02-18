// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, avoid_print, unused_local_variable, unnecessary_const, no_leading_underscores_for_local_identifiers, unused_element, unnecessary_new, unused_field

import 'package:flutter/material.dart';
import 'package:journee/account.dart';
import 'package:journee/create.dart';
import 'package:journee/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const List<Widget> _pages = <Widget>[
      HomePostView(),
      CreateDiaryPage(),
      AccountPage()
    ];

    return Scaffold(
      body: IndexedStack(
      index: _selectedIndex,
      children: _pages
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        mouseCursor: SystemMouseCursors.grab,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: const<BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, 
      ),
    );
  }
}

class HomePostView extends StatefulWidget {
  const HomePostView({super.key});

  @override
  State<HomePostView> createState() => _HomePostViewState();
}

class _HomePostViewState extends State<HomePostView> {
    final _future = Supabase.instance.client
    .from('posts')
    .select('''*, users(*), threads ( * ), categories ( * )''')
    .order('created_at',  ascending: false);
  
    Future<void> _refresh() async {
    try {
      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (_) => false
      );
    } catch (e) {
      print('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home")
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if(!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
              final posts = snapshot.data!;
              
              return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: ((context, index) {
                final post = posts[index];
                final user = post['users'];
                final thread = post['threads'];
                int threadLength = post['threads'].length;
                DateTime myDateTime = DateTime.parse(post['created_at']);
                return ListTile(
                  onTap: () {
                      Navigator.push(context, MaterialPageRoute<void>(
                        builder: (context) => ViewPostRoute(puid: new Puid(post['puid']))));
                  },
                  contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                  isThreeLine: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(48.0),
                    child: Image.network(user['avatar_url']
                    )
                  ),
                  title: Text(user['name'], style: TextStyle(fontSize: 16)),
                  trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['details'], maxLines: 1, style: TextStyle(fontSize: 12.5)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 20),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text('$threadLength'),
                            ),
                          ],
                        ),
                      ),
                      
                    ],
                  ),
                );
              }),
              );
          },
        ),
      ),
    );
  }
}