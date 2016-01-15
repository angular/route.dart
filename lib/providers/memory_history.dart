part of route.history_provider;

class MemoryHistory implements HistoryProvider {
  // keep a list of urls
  List<String> _urlList;

  // keep track of a unique namespace for internal urls
  final String _namespace = 'router${new Uuid().v4()}:';

  // broadcast changes to url
  StreamController<String> _urlStreamController;
  Stream<String> _urlStream;

  MemoryHistory({List<String> urlHistory}) {
    _urlList = urlHistory ?? [''];
    _urlStreamController = new StreamController<String>();
    _urlStream = _urlStreamController.stream.asBroadcastStream();
  }

  Stream get onChange => _urlStream;

  String get path => _urlList.isNotEmpty ? _urlList.last : '';

  String get urlStub => _namespace;

  String pageTitle = '';

  void clickHandler(Event e, RouterLinkMatcher linkMatcher,
      Future<bool> gotoUrl(String url)) {
    Element el = e.target;
    while (el != null && el is! AnchorElement) {
      el = el.parent;
    }

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

  void go(String path, bool replace) {
    if (replace) {
      _urlList.removeLast();
    }
    _urlList.add(path);
    _urlStreamController.add(path);
  }

  void back() {
    if (_urlList.length > 1) {
      _urlList.removeLast();
      _urlStreamController.add(_urlList.last);
    }
  }
}
