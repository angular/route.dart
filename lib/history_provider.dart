library route.history_provider;

import 'dart:async';
import 'dart:html';

import 'link_matcher.dart';

abstract class HistoryProvider {
  void clickHandler(
      Event e, RouterLinkMatcher linkMatcher, Future<bool> gotoUrl(String url));
  Stream get onChange;
  String getPath();
  void go(String path, String title, bool replace);
  void back();
  String get urlStub;
}

class BrowserHistory implements HistoryProvider {
  Window _window;

  BrowserHistory({Window windowImpl}) {
    _window = windowImpl ?? window;
  }

  Stream get onChange => _window.onPopState;
  String get urlStub => '';

  void clickHandler(Event e, RouterLinkMatcher linkMatcher,
      Future<bool> gotoUrl(String url)) {
    Element el = e.target;
    while (el != null && el is! AnchorElement) {
      el = el.parent;
    }
    ;
    if (el == null) return;
    assert(el is AnchorElement);
    AnchorElement anchor = el;
    if (!linkMatcher.matches(anchor)) {
      return;
    }
    if (anchor.host == _window.location.host) {
      e.preventDefault();
      gotoUrl('${anchor.pathname}${anchor.search}');
    }
  }

  String getPath() => '${_window.location.pathname}${_window.location.search}'
      '${_window.location.hash}';

  void go(String path, String title, bool replace) {
    if (title == null) {
      title = (_window.document as HtmlDocument).title;
    }
    if (replace) {
      _window.history.replaceState(null, title, path);
    } else {
      _window.history.pushState(null, title, path);
    }
    if (title != null) {
      (_window.document as HtmlDocument).title = title;
    }
  }

  void back() {
    _window.history.back();
  }
}

class HashHistory implements HistoryProvider {
  Window _window;

  HashHistory({Window windowImpl}) {
    _window = windowImpl ?? window;
  }

  Stream get onChange => _window.onHashChange;
  String get urlStub => '#';

  void clickHandler(Event e, RouterLinkMatcher linkMatcher,
      Future<bool> gotoUrl(String url)) {
    Element el = e.target;
    while (el != null && el is! AnchorElement) {
      el = el.parent;
    }
    ;
    if (el == null) return;
    assert(el is AnchorElement);
    AnchorElement anchor = el;
    if (!linkMatcher.matches(anchor)) {
      return;
    }
    if (anchor.host == _window.location.host) {
      e.preventDefault();
      gotoUrl(_normalizeHash(anchor.hash));
    }
  }

  String getPath() => _normalizeHash(_window.location.hash);

  String _normalizeHash(String hash) => hash.isEmpty ? '' : hash.substring(1);

  void go(String path, String title, bool replace) {
    if (replace) {
      _window.location.replace('#$path');
    } else {
      _window.location.assign('#$path');
    }
    if (title != null) {
      (_window.document as HtmlDocument).title = title;
    }
  }

  void back() {
    _window.history.back();
  }
}

class MemoryHistory implements HistoryProvider {
  // keep a list of urls
  List<String> _urlList;

  // keep track of a unique namespace for internal urls
  final String _namespace =
      'router${new DateTime.now().millisecondsSinceEpoch}:';

  // broadcast changes to url
  StreamController<String> _urlStreamController;
  Stream<String> _urlStream;

  MemoryHistory() {
    _urlList = [''];
    _urlStreamController = new StreamController<String>();
    _urlStream = _urlStreamController.stream.asBroadcastStream();
  }

  Stream get onChange => _urlStream;
  String get urlStub => _namespace;

  void clickHandler(Event e, RouterLinkMatcher linkMatcher,
      Future<bool> gotoUrl(String url)) {
    Element el = e.target;
    while (el != null && el is! AnchorElement) {
      el = el.parent;
    }
    ;
    if (el == null) return;
    assert(el is AnchorElement);
    AnchorElement anchor = el;
    if (!linkMatcher.matches(anchor)) {
      return;
    }
    if (anchor.origin.startsWith(urlStub)) {
      e.preventDefault();
      gotoUrl(anchor.pathname);
    }
  }

  String _normalizeHash(String hash) => hash.isEmpty ? '' : hash.substring(1);

  String getPath() {
    return _urlList.length > 0 ? _urlList.last : '';
  }

  void go(String path, String title, bool replace) {
    if (replace) {
      _urlList.removeLast();
    }
    _urlList.add(path);
    _urlStreamController.add(path);
  }

  void back() {
    _urlList.removeLast();
    _urlStreamController.add(_urlList.last);
  }
}
