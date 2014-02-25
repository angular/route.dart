// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.test_mocks;

import 'dart:html';
import 'package:unittest/mock.dart';

class MockWindow extends Mock implements Window {
  MockHistory history = new MockHistory();
  MockLocation location = new MockLocation();
  MockDocument document = new MockDocument();

  noSuchMethod(_) => super.noSuchMethod(_);
}

class MockHistory extends Mock implements History {
  //TODO(pavelgj): ugly hack for making tests run in dart2js
  void pushState(Object data, String title, [String url]) {
    log.add(new LogEntry(name, 'pushState', [data, title, url], Action.IGNORE));
  }

  //TODO(pavelgj): ugly hack for making tests run in dart2js
  void replaceState(Object data, String title, [String url]) {
    log.add(new LogEntry(name, 'replaceState', [data, title, url], Action.IGNORE));
  }
  noSuchMethod(_) => super.noSuchMethod(_);
}

class MockLocation extends Mock implements Location {
  noSuchMethod(_) => super.noSuchMethod(_);
}

class MockDocument extends Mock implements HtmlDocument {
  //TODO(pavelgj): ugly hack for making tests run in dart2js
  set title(String title) =>
      log.add(new LogEntry(name, '=title', [title], Action.IGNORE));
  noSuchMethod(_) => super.noSuchMethod(_);
}
