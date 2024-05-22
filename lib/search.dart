// ignore_for_file: unused_import, prefer_const_constructors, avoid_print, unused_local_variable, no_leading_underscores_for_local_identifiers

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journee/post.dart';
import 'package:journee/splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

Widget searchMode() {
  
  String? _searchingWithQuery;
  late Iterable<Widget> _lastOptions = <Widget>[];
  
  return SearchAnchor(
    viewHintText: 'Search',
     builder: (BuildContext context, SearchController controller) {
        return IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            controller.openView();
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) async {
        _searchingWithQuery = controller.text;
       final data = await supabase
       .rpc('search_posts_and_threads', params: {'keyword': '$_searchingWithQuery' });
       
        if (_searchingWithQuery != controller.text) {
          return _lastOptions;
        }

        _lastOptions = List<ListTile>.generate(data.length, (int index) {
          // print(data);
          final String item = data[index]['details'];
          final String date = data[index]['created_at'];
          final String puid = data[index]['puid'];
          DateTime myDateTime = DateTime.parse(date);
          return ListTile(
            onTap: () {
              context.go('/post/$puid');
            },
            title: Text(item, maxLines: 2),
            trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
          );
        });

        return _lastOptions;
      },
  );
}

Widget categorySearchMode(String cuid, String catName) {
  String? _searchingWithQuery;
  late Iterable<Widget> _lastOptions = <Widget>[];
  
  return SearchAnchor(
    viewHintText: 'Search on $catName',
     builder: (BuildContext context, SearchController controller) {
        return IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            controller.openView();
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) async {
        _searchingWithQuery = controller.text;
       final data = await supabase
        .from('posts')
        .select()
        .ilike('details', '%${_searchingWithQuery!}%')
        .eq('cuid', cuid)
        .order('created_at',  ascending: false);
        
        if (_searchingWithQuery != controller.text) {
          return _lastOptions;
        }

        _lastOptions = List<ListTile>.generate(data.length, (int index) {
          final String item = data[index]['details'];
          final String date = data[index]['created_at'];
          final String puid = data[index]['puid'];
          DateTime myDateTime = DateTime.parse(date);
          return ListTile(
            onTap: () {
              context.go('/post/$puid');
            },
            title: Text(item, maxLines: 2),
            trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
          );
        });

        return _lastOptions;
      },
  );
}

Widget userPostSearchMode(String uuid, String userName) {
  String? _searchingWithQuery;
  late Iterable<Widget> _lastOptions = <Widget>[];
  
  return SearchAnchor(
    viewHintText: "Search $userName's posts",
     builder: (BuildContext context, SearchController controller) {
        return IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {
            controller.openView();
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) async {
        _searchingWithQuery = controller.text;
       final data = await supabase
        .from('posts')
        .select()
        .ilike('details', '%${_searchingWithQuery!}%')
        .eq('uuid', uuid)
        .order('created_at',  ascending: false);
        
        if (_searchingWithQuery != controller.text) {
          return _lastOptions;
        }

        _lastOptions = List<ListTile>.generate(data.length, (int index) {
          final String item = data[index]['details'];
          final String date = data[index]['created_at'];
          final String puid = data[index]['puid'];
          DateTime myDateTime = DateTime.parse(date);
          return ListTile(
            onTap: () {
              context.go('/post/$puid');
            },
            title: Text(item, maxLines: 2),
            trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
          );
        });

        return _lastOptions;
      },
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? _searchingWithQuery;
  late Iterable<Widget> _lastOptions = <Widget>[];
  
  @override 
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
  return SearchAnchor(
    isFullScreen: true,
    viewHintText: 'Search',
     builder: (BuildContext context, SearchController controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 32, 8, 0),
          child: TextField(
            autofocus: true,
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Search anything on Journee",
              border: InputBorder.none
            ),
            onChanged: (value) {
              // Debounce.run(Duration(milliseconds: 500), () {
                setState(() {
                  _searchingWithQuery = value; // Set the query value
                  controller.openView();
                });
              // });
            }
          ),
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) async {
        _searchingWithQuery = controller.text;
       final data = await supabase
       .rpc('search_posts_and_threads', params: {'keyword': '$_searchingWithQuery' });
       
        if (_searchingWithQuery != controller.text) {
          return _lastOptions;
        }

        _lastOptions = List<ListTile>.generate(data.length, (int index) {
          // print(data);
          final String item = data[index]['details'];
          final String date = data[index]['created_at'];
          final String puid = data[index]['puid'];
          DateTime myDateTime = DateTime.parse(date);
          return ListTile(
            onTap: () {
              context.go('/post/$puid');
            },
            title: Text(item, maxLines: 2),
            trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
          );
        });

        return _lastOptions;
      },
  );
}
}