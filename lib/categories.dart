// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, no_logic_in_create_state, avoid_print, unnecessary_null_comparison, prefer_const_literals_to_create_immutables, dead_code

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/home.dart';
import 'package:journee/search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _futureCat = Supabase.instance.client
    .from('categories')
    .select('''*, users(*), posts(*)''');
    // .order('created_at',  ascending: false);
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCat,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: ((context, index) {
              final category = categories[index];
              final user = category['users'];
              final cuid = category['cuid'];
              int length = category['posts'].length;
              
              if (length > 0 ) {
                if(user == null) {
                  return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: ListTile(
                    onTap: () {
                      kIsWeb ? context.go('/category/$cuid') : context.push('/category/$cuid');
                    },
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(48.0),
                        child: Icon(Icons.people, size: 48.0)
                      ),
                    ),
                    title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0,0,8,0),
                            child: Text(category['name']),
                          ),
                          Text('by System', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    trailing: Text('$length posts'),
                  ),
                );
                } 
                else {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: ListTile(
                      onTap: () {
                        kIsWeb ? context.go('/category/$cuid') : context.push('/category/$cuid');
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(48.0),
                        child: Image.network(user['avatar_url']
                        )
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0,0,8,0),
                            child: Text(category['name']),
                          ),
                          Text('by '+user['name'], style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Text('$length posts'),
                    ),
                  );
                }
              }
              return Container();
              
            }),
          );
        }
      ),
    );
  }
}

class CategoriesViewPage extends StatefulWidget {
  final String? cuid;
  final bool? home;
  const CategoriesViewPage({super.key, required this.cuid, required this.home});

  @override
  State<CategoriesViewPage> createState() => _CategoriesViewPageState(cuid: cuid, home: home);
}

class _CategoriesViewPageState extends State<CategoriesViewPage> {
  final supabase = Supabase.instance.client;
  final String? cuid;
  final bool? home;

  _CategoriesViewPageState({required this.cuid, required this.home});

  late final _futureCatView = supabase
  .from('posts')
  .select('''*, users(*), threads ( * ), categories ( * ), locations(*)''')
  .eq('cuid', cuid!)
  .order('created_at',  ascending: false);
  
  ValueNotifier<String> catName = ValueNotifier<String>('');
  String? catDesc;
  late List<Map<String, dynamic>> fetchedData = [];
  
  Future<void> refreshPage() async{
    context.pushReplacement('/category/$cuid');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCatView,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.done) {
            final posts = snapshot.data!;
            // print(posts);
            if(snapshot.data!.isNotEmpty) {
            fetchedData = posts;
            catDesc = posts[0]['categories']['desc'];
            catName.value = snapshot.data![0]['categories']['name'];
                                   
            Widget categoryViewUI() {
            // FOOD REVIEW CATEGORY VIEW
            if(posts[0]['cuid'] == '368d3855-965d-4f13-b741-7975bbac80bf' && posts.isNotEmpty) {
              return NewPostView(posts, snapshot, true, true);
              }

              // NON FOOD REVIEW CATEGORY VIEW
              return NewPostView(posts, snapshot, false, true);
              // return OldPostView(posts, snapshot);
              
            }
            
            if(home == true) {
              return Scaffold(
                body: RefreshIndicator(
                  onRefresh: () => refreshPage(),
                  child: categoryViewUI())
              );
            } return Scaffold(
              appBar: AppBar(
                title: Text(catName.value),
                actions: <Widget> [categorySearchMode(cuid!, catName.value)],
              ),
              body: RefreshIndicator(
                onRefresh: () => refreshPage(),
                child: categoryViewUI())
            );
            }
            return Center(child: Text("There are no food reviews!"));
          }
          return const Center(child: CircularProgressIndicator());
        }
      );
  }
}