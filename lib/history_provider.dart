library route.history_provider;

import 'dart:async';
import 'dart:html';

import 'package:uuid/uuid.dart';

import 'link_matcher.dart';

part 'providers/browser_history.dart';
part 'providers/hash_history.dart';
part 'providers/memory_history.dart';

abstract class HistoryProvider {
  Stream get onChange;
  String get path;
  String get urlStub;
  String pageTitle;

  void clickHandler(
      Event e, RouterLinkMatcher linkMatcher, Future<bool> gotoUrl(String url));
  void go(String path, bool replace);
  void back();
}
