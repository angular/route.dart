library route.click_handler_test;

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';
import 'package:route_hierarchical/click_handler.dart';
import 'package:route_hierarchical/client.dart';
import 'package:route_hierarchical/link_matcher.dart';

import 'util/mocks.dart';

main() {
  group('DefaultWindowLinkHandler', () {

    WindowClickHandler linkHandler;
    MockRouter router;
    MockWindow mockWindow;
    Element root;
    StreamController onHashChangeController;

    setUp(() {
      router = new MockRouter();
      mockWindow = new MockWindow();
      mockWindow.location.when(callsTo('get host'))
          .alwaysReturn(window.location.host);
      mockWindow.location.when(callsTo('get hash')).alwaysReturn('');
      onHashChangeController = new StreamController();
      mockWindow.when(callsTo('get onHashChange'))
          .alwaysReturn(onHashChangeController.stream);
      root = new DivElement();
      document.body.append(root);
      linkHandler = new DefaultWindowClickHandler(new DefaultRouterLinkMatcher(), router, true, mockWindow,
          (String hash) => hash.isEmpty ? '' : hash.substring(1));
    });

    tearDown(() {
      root.remove();
    });

    MouseEvent _createMockMouseEvent({String anchorTarget, String anchorHref}) {
      AnchorElement anchor = new AnchorElement();
      if (anchorHref != null) anchor.href = anchorHref;
      if (anchorTarget != null) anchor.target = anchorTarget;

      MockMouseEvent mockMouseEvent = new MockMouseEvent();
      mockMouseEvent.when(callsTo('get target')).alwaysReturn(anchor);
      mockMouseEvent.when(callsTo('get path')).alwaysReturn([anchor]);
      return mockMouseEvent;
    }

    test('should process AnchorElements which have target set', () {
      MockMouseEvent mockMouseEvent = _createMockMouseEvent(anchorHref: '#test');
      linkHandler(mockMouseEvent);
      LogEntryList logEntries = router.getLogs(callsTo('gotoUrl'));
      expect(logEntries.logs.length, 1);
      expect(logEntries.logs.first.args.contains("test"), isTrue);
    });

    test('should process AnchorElements which has target set to _blank, _self, _top or _parent', () {
      MockMouseEvent mockMouseEvent = _createMockMouseEvent(anchorHref: '#test',
          anchorTarget: '_blank');
      linkHandler(mockMouseEvent);

      mockMouseEvent = _createMockMouseEvent(anchorHref: '#test',
          anchorTarget: '_self');
      linkHandler(mockMouseEvent);

      mockMouseEvent = _createMockMouseEvent(anchorHref: '#test',
          anchorTarget: '_top');
      linkHandler(mockMouseEvent);

      mockMouseEvent = _createMockMouseEvent(anchorHref: '#test',
          anchorTarget: '_parent');
      linkHandler(mockMouseEvent);

      // We expect 0 calls to router.gotoUrl
      LogEntryList logEntries = router.getLogs(callsTo('gotoUrl'));
      expect(logEntries.logs.length, 0);
    });

    test('should process AnchorElements which has a child', () {
      Element anchorChild = new DivElement();

      AnchorElement anchor = new AnchorElement();
      anchor.href = '#test';
      anchor.append(anchorChild);

      MockMouseEvent mockMouseEvent = new MockMouseEvent();
      mockMouseEvent.when(callsTo('get target')).alwaysReturn(anchorChild);
      mockMouseEvent.when(callsTo('get path')).alwaysReturn([anchorChild, anchor]);

      linkHandler(mockMouseEvent);
      LogEntryList logEntries = router.getLogs(callsTo('gotoUrl'));
      expect(logEntries.logs.length, 1);
      expect(logEntries.logs.first.args.contains("test"), isTrue);
    });

    test('should be called if event triggerd on anchor element', () {
      AnchorElement anchor = new AnchorElement();
      anchor.href = '#test';
      root.append(anchor);

      var router = new Router(useFragment: true,
          clickHandler: expectAsync((e) {}), windowImpl: mockWindow);
      router.listen(appRoot: root);

      // Trigger handle method in linkHandler
      anchor.dispatchEvent(new MouseEvent('click'));
    });

    test('should be called if event triggerd on child of an anchor element', () {
      Element anchorChild = new DivElement();
      AnchorElement anchor = new AnchorElement();
      anchor.href = '#test';
      anchor.append(anchorChild);
      root.append(anchor);

      var router = new Router(useFragment: true,
          clickHandler: expectAsync((e) {}), windowImpl: mockWindow);
      router.listen(appRoot: root);

      // Trigger handle method in linkHandler
      anchorChild.dispatchEvent(new MouseEvent('click'));
    });
  });
}
