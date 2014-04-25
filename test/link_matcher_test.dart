library route.link_matcher_test;

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:route_hierarchical/link_matcher.dart';

main() {

  group('DefaultRouterLinkMatcher', () {
    RouterLinkMatcher linkMatcher = new DefaultRouterLinkMatcher();

    test('should not match anchor element which has target set to _blank, _top, _parent or _self', () {
      AnchorElement anchor = new AnchorElement();

      anchor.target = '_blank';
      expect(linkMatcher.matches(anchor), isFalse);

      anchor.target = '_top';
      expect(linkMatcher.matches(anchor), isFalse);

      anchor.target = '_parent';
      expect(linkMatcher.matches(anchor), isFalse);

      anchor.target = '_self';
      expect(linkMatcher.matches(anchor), isFalse);
    });
  });
}