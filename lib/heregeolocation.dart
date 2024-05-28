// ignore_for_file: avoid_print, prefer_const_constructors, no_logic_in_create_state, camel_case_types

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

Future<Map<String, dynamic>?> fetchEndpointData(lat, long) async {
  final dio = Dio();
  var hereAppAPI = dotenv.env['hereApiKey']!;
  String hereEndpointConstructor(lat, long) {
    return 'https://revgeocode.search.hereapi.com/v1/revgeocode?at=$lat%2C$long&lang=en-US&apiKey=$hereAppAPI';
  }

  final response = await dio.get(hereEndpointConstructor(lat, long));
  Map<String, dynamic>? fetchedData = response.data['items'][0];
  return fetchedData;
}
