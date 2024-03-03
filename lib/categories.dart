// ignore_for_file: prefer_const_constructors, prefer_interpolation_to_compose_strings, no_logic_in_create_state, avoid_print

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/search.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

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
              final length = category['posts'].length;
              
              if(user == null) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: ListTile(
                    onTap: () {
                      context.push('/category/$cuid');
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
                      context.push('/category/$cuid');
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
              
            }),
          );
        }
      ),
    );
  }
}

class CategoriesViewPage extends StatefulWidget {
  final String? cuid;
  const CategoriesViewPage({super.key, required this.cuid});

  @override
  State<CategoriesViewPage> createState() => _CategoriesViewPageState(cuid: cuid);
}

class _CategoriesViewPageState extends State<CategoriesViewPage> {
  final String? cuid;

  _CategoriesViewPageState({Key? key, required this.cuid});

  late final _futureCatView = Supabase.instance.client
  .from('posts')
  .select('''*, users(*), threads ( * ), categories ( * )''')
  .eq('cuid', cuid!)
  .order('created_at',  ascending: false);


  String catName = 'this category';
  String? catDesc;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Category"),
        actions: <Widget> [categorySearchMode(cuid!, catName)],
      ),
       body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCatView,
        builder: (context, snapshot) {
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final posts = snapshot.data!;
          catName = posts[0]['categories']['name'];
          catDesc = posts[0]['categories']['desc'];
          final length = posts.length;

          return Column(
            children: [
              ListTile(
                title: Text(catName),
                subtitle: catDesc != null ? Text(catDesc!) : Text("No description available"),
                trailing: Text('$length posts'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: ((context, index) {
                    final post = posts[index];
                    final user = post['users'];
                    final puid = post['puid'];
                    catName = posts[0]['categories']['name'];
                    int threadLength = post['threads'].length;
                    final special = post['type'];
                    DateTime myDateTime = DateTime.parse(post['created_at']);
                    
                    return ListTile(
                      onTap: () {
                        context.push('/post/$puid');
                      },
                      contentPadding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      isThreeLine: true,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(48.0),
                        child: Image.network(user['avatar_url']
                        )
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0,0,4,0),
                                child: Text(user['name']),
                              ),
                              if(special == 'Special') Padding(
                                padding: const EdgeInsets.fromLTRB(5,0,0,0),
                                child: Icon(Icons.star_border_outlined),
                              )
                            ],
                          ),
                        ],
                      ),
                      trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['details'], maxLines: 3, style: TextStyle(fontSize: 12.5, height: 2)),
                          if(post['mediaUrl_preview'] != null) Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(post['mediaUrl_preview'], width: 400)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                            child: Row(
                              children: [
                                if(post['mediaUrl_preview'] == null && post['mediaUrl'] != null) Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 5, 5, 0),
                                  child: Icon(Icons.image_outlined, size: 22),
                                ),
                                if(post['allowReply']) Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 20),
                                      if(threadLength > 0) Padding(
                                        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                        child: Text('$threadLength'),
                                      ),
                                    ],
                                  ),
                                ),
                                if(!post['allowReply']) Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Icon(Icons.comments_disabled_outlined, size: 20),
                                      if(threadLength > 0) Padding(
                                        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                        child: Text('$threadLength'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                    }
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}