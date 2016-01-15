library route.url_matcher_test;

import 'package:test/test.dart';
import 'package:route_hierarchical/url_matcher.dart';

main() {
  group('UrlMatch', () {
    String match = '/foo/bar123/aux';
    String tail = '?some=tail';
    Map parameters = {'baz': '123'};

    test('should return corresponding string', () {
      UrlMatch matcher = new UrlMatch(match, tail, parameters);
      expect(matcher.toString(),
          equals('{/foo/bar123/aux, ?some=tail, {baz: 123}}'));
    });

    test('should return predictable hash code', () {
      UrlMatch matcher = new UrlMatch(match, tail, parameters);
      UrlMatch matcher2 = new UrlMatch(match, tail, parameters);
      expect(matcher.hashCode, equals(matcher2.hashCode));
    });
  });
}
