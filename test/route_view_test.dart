library route.route_view_test;

import 'package:test/test.dart';
import 'package:route_hierarchical/client.dart';

main() {
  group('RouteView', () {
    Router router;
    Route fooRoute;
    Route fooRoute2;
    RouteView routeView;

    final Map routeViewParams = {'rvParam1': 'something'};
    final Map routeViewQueryParams = {'what': 'ever'};

    setUp(() {
      router = new Router();
      router.root
        ..addRoute(
            name: 'foo',
            path: '/foo',
            mount: (mount) => mount.addRoute(
                name: 'foo2',
                path: '/foo2/:fooParam',
                dontLeaveOnParamChanges: true,
                pageTitle: 'something'));
      fooRoute = router.findRoute('foo');
      fooRoute2 = router.findRoute('foo.foo2');
      routeView = new RouteView(fooRoute2,
          parameters: routeViewParams, queryParameters: routeViewQueryParams);
      router.route('/foo/foo2/abc?something=else');
    });

    test('should retain supplied parameters', () {
      expect(routeView.parameters, equals(routeViewParams));
      expect(routeView.parameters, isNot(equals(fooRoute2.parameters)));
    });

    test('should retain supplied query parameters', () {
      expect(routeView.queryParameters, equals(routeViewQueryParams));
      expect(
          routeView.queryParameters, isNot(equals(fooRoute2.queryParameters)));
    });

    group('proxy operations', () {
      test('isActive should match route.isActive', () {
        expect(routeView.isActive, isTrue);
        expect(routeView.isActive, equals(fooRoute2.isActive));
      });

      test('path should match route.path', () {
        expect(routeView.path, equals(fooRoute2.path));
      });

      test('name should match route.name', () {
        expect(routeView.name, equals('foo2'));
        expect(routeView.name, equals(fooRoute2.name));
      });

      test('parent should match route.parent', () {
        expect(routeView.parent, equals(fooRoute));
        expect(routeView.parent, equals(fooRoute2.parent));
      });

      test('dontLeaveOnParamChanges should match route.dontLeaveOnParamChanges',
          () {
        expect(routeView.dontLeaveOnParamChanges, isTrue);
        expect(routeView.dontLeaveOnParamChanges,
            equals(fooRoute2.dontLeaveOnParamChanges));
      });

      test('pageTitle should match route.pageTitle', () {
        expect(routeView.pageTitle, 'something');
        expect(routeView.pageTitle, equals(fooRoute2.pageTitle));
      });

      test('lifecycle events should match those of the supplied route', () {
        expect(routeView.onPreEnter, equals(fooRoute2.onPreEnter));
        expect(routeView.onPreLeave, equals(fooRoute2.onPreLeave));
        expect(routeView.onLeave, equals(fooRoute2.onLeave));
        expect(routeView.onEnter, equals(fooRoute2.onEnter));
      });

      test('toString should match route.toString', () {
        expect(routeView.toString(), '[Route: foo2]');
        expect(routeView.toString(), equals(fooRoute2.toString()));
      });
    });

    group('unsupported operations', () {
      test('should throw if adding a route', () {
        expect(() => routeView.addRoute(name: 'baz', path: '/baz'),
            throwsUnsupportedError);
      });

      test('should throw if finding a route', () {
        expect(() => routeView.findRoute('baz'), throwsUnsupportedError);
      });

      test('should throw if requesting a RouteHandle', () {
        expect(() => routeView.newHandle(), throwsUnsupportedError);
      });
    });
  });
}
