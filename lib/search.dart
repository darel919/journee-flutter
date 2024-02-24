// ignore_for_file: unused_import, prefer_const_constructors, avoid_print, unused_local_variable, no_leading_underscores_for_local_identifiers

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journee/post.dart';
import 'package:journee/splash.dart';
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
       final data = await supabase.from('posts').select()
       .ilike('details', '%${_searchingWithQuery!}%').order('created_at',  ascending: false);
        
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
              Navigator.push(context, MaterialPageRoute<void>(
                builder: (context) => ViewPostRoute(puid: Puid(puid))));
            },
            title: Text(item, maxLines: 2),
            trailing: Text(timeago.format(myDateTime, locale: 'en_short')),
          );
        });

        return _lastOptions;
      },
  );
}