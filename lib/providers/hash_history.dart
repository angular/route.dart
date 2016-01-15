part of route.history_provider;

class HashHistory implements HistoryProvider {
  Window _window;
  String _pageTitle;

  HashHistory({Window windowImpl}) {
    _window = windowImpl ?? window;
  }

  Stream get onChange => _window.onHashChange;

  String get path => _normalizeHash(_window.location.hash);

  String get urlStub => '#';

  String get pageTitle =>
      _pageTitle ?? (_window.document as HtmlDocument).title;

  void set pageTitle(String title) {
    if (title != null) {
      _pageTitle = title;
      (_window.document as HtmlDocument).title = _pageTitle;
    }
  }

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
    if (anchor.host == _window.location.host) {
      e.preventDefault();
      gotoUrl(_normalizeHash(anchor.hash));
    }
  }

  void go(String path, bool replace) {
    if (replace) {
      _window.location.replace('#$path');
    } else {
      _window.location.assign('#$path');
    }
  }

  void back() {
    _window.history.back();
  }

  String _normalizeHash(String hash) => hash.isEmpty ? '' : hash.substring(1);
}
