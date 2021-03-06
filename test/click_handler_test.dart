library route.click_handler_test;

import 'dart:html';
import 'dart:async';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
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
      when(mockWindow.location.host).thenReturn(window.location.host);
      when(mockWindow.location.hash).thenReturn('');
      onHashChangeController = new StreamController();
      when(mockWindow.onHashChange).thenReturn(onHashChangeController.stream);
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
      when(mockMouseEvent.target).thenReturn(anchor);
      when(mockMouseEvent.path).thenReturn([anchor]);
      return mockMouseEvent;
    }

    test('should process AnchorElements which have target set', () {
      MockMouseEvent mockMouseEvent = _createMockMouseEvent(anchorHref: '#test');
      linkHandler(mockMouseEvent);
      var result = verify(router.gotoUrl(captureAny));
      result.called(1);
      expect(result.captured.first, "test");
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
      verifyNever(router.gotoUrl(any));
    });

    test('should process AnchorElements which has a child', () {
      Element anchorChild = new DivElement();

      AnchorElement anchor = new AnchorElement();
      anchor.href = '#test';
      anchor.append(anchorChild);

      MockMouseEvent mockMouseEvent = new MockMouseEvent();
      when(mockMouseEvent.target).thenReturn(anchorChild);
      when(mockMouseEvent.path).thenReturn([anchorChild, anchor]);

      linkHandler(mockMouseEvent);
      var result = verify(router.gotoUrl(captureAny));
      result.called(1);
      expect(result.captured.first, "test");
    });

    test('should be called if event triggerd on anchor element', () {
      AnchorElement anchor = new AnchorElement();
      anchor.href = '#test';
      root.append(anchor);

      var router = new Router(
          useFragment: true,
//          TODO Understand why adding the following line causes failure
//          clickHandler: expectAsync((e) {}) as WindowClickHandler,
          windowImpl: mockWindow);
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

      var router = new Router(
          useFragment: true,
//          TODO Understand why adding the following line causes failure
//          clickHandler: expectAsync((e) {}) as WindowClickHandler,
          windowImpl: mockWindow);
      router.listen(appRoot: root);

      // Trigger handle method in linkHandler
      anchorChild.dispatchEvent(new MouseEvent('click'));
    });
  });
}
