import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../domain/update/release_history.dart';

Future<List<ReleaseHistoryEntry>> bundledReleaseHistory() async =>
    ReleaseHistoryEntry.parse(
      jsonDecode(await rootBundle.loadString('website/changelog.json')),
    );

Future<List<ReleaseHistoryEntry>> onlineReleaseHistory(Dio dio) async {
  final response = await dio.get<String>(
    'https://zhaozhaoyue.top/towork/changelog.json',
    options: Options(responseType: ResponseType.plain, followRedirects: false),
  );
  return ReleaseHistoryEntry.parse(jsonDecode(response.data ?? ''));
}
