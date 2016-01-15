// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.test.util.mocks;

import 'dart:async';
import 'dart:html';

import 'package:mockito/mockito.dart';
import 'package:route_hierarchical/client.dart';

class MockWindow extends Mock implements Window {
  MockHistory history;
  MockLocation location;
  MockDocument document;

  StreamController _onHashChangeController;
  StreamController _onPopStateController;
  List<String> _urlList;

  MockWindow() {
    _urlList = [];
    history = new MockHistory(_urlList);
    location = new MockLocation(_urlList);
    document = new MockDocument();

    when(location.host).thenReturn(window.location.host);
    when(location.hash).thenReturn('');
    when(document.title).thenReturn('page title');

    // keep track of a basic history list
    _onHashChangeController = new StreamController();
    when(this.onHashChange)
        .thenReturn(_onHashChangeController.stream.asBroadcastStream());
    _onPopStateController = new StreamController();
    when(this.onPopState)
        .thenReturn(_onPopStateController.stream.asBroadcastStream());
  }

  changeHash(String hash) async {
    await _onHashChangeController.add(hash);
    await _onPopStateController.add(hash);
  }
}

class MockHistory extends Mock implements History {
  List<String> urlList;
  MockHistory(this.urlList);
  bool backCalled = false;

  back() {
    backCalled = true;
    urlList.removeLast();
  }

  replaceState(Object data, String title, [String url]) {
    urlList.removeLast();
    urlList.add(url);
  }

  pushState(Object data, String title, [String url]) {
    urlList.add(url);
  }
}

class MockLocation extends Mock implements Location {
  List<String> urlList;
  MockLocation(this.urlList);

  replace(String url) {
    urlList.removeLast();
    urlList.add(url);
  }

  assign([String url]) {
    urlList.add(url);
  }
}

class MockDocument extends Mock implements HtmlDocument {}

class MockMouseEvent extends Mock implements MouseEvent {
  MockMouseEvent({EventTarget target, List<Node> path}) {
    when(this.target).thenReturn(target);
    when(this.path).thenReturn(path);
  }

  MockMouseEvent.withAnchor({String target: '', String href: ''}) {
    AnchorElement anchor = new AnchorElement();
    anchor.href = href;
    anchor.target = target;

    when(this.target).thenReturn(anchor);
    when(this.path).thenReturn([anchor]);
  }
}

class MockRouter extends Mock implements Router {}

class MockRoutable implements Routable {
  bool routesConfigured = false;
  void configureRoute(Route router) {
    routesConfigured = true;
  }
}
