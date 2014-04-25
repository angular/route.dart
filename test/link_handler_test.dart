library route.link_matcher_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';
import 'package:route_hierarchical/client.dart';
import 'package:route_hierarchical/link_handler.dart';
import 'package:route_hierarchical/link_matcher.dart';

import 'util/mocks.dart';

main() {
  group('DefaultWindowLinkHandler', () {

    WindowClickHandler linkHandler;
    MockRouter router;

    setUp(() {
      router = new MockRouter();
      linkHandler = new DefaultWindowLinkHandler(new DefaultRouterLinkMatcher(), router, true, window,
          (String hash) => hash.isEmpty ? '' : hash.substring(1));
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

    test('it should process AnchorElements which have target set', () {
      MockMouseEvent mockMouseEvent = _createMockMouseEvent(anchorHref: '#test');
      linkHandler(mockMouseEvent);
      LogEntryList logEntries = router.getLogs(callsTo('gotoUrl'));
      expect(logEntries.logs.length, 1);
      expect(logEntries.logs.first.args.contains("test"), isTrue);
    });

    test('it should process AnchorElements which has target set to _blank, _self, _top or _parent', () {
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

    test('it should process AnchorElements which has a child', () {
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

    test('it should be called if event triggerd on anchor element', () {
      AnchorElement anchor = new AnchorElement();
      anchor.href = '#test';
      document.body.append(anchor);

      var router = new Router(useFragment: true, linkHandler: expectAsync((e) {}));
      router.listen();

      // Trigger handle method in linkHandler
      anchor.dispatchEvent(new MouseEvent('click'));
    });

    test('it should be called if event triggerd on child of an anchor element', () {
      Element anchorChild = new DivElement();
      AnchorElement anchor = new AnchorElement();
      anchor.href = '#test';
      anchor.append(anchorChild);
      document.body.append(anchor);

      var router = new Router(useFragment: true, linkHandler: expectAsync((e) {}));
      router.listen();

      // Trigger handle method in linkHandler
      anchorChild.dispatchEvent(new MouseEvent('click'));
    });
  });
}

class MockRouter extends Mock implements Router {}