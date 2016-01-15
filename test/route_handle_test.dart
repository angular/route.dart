library route.route_handle_test;

import 'package:test/test.dart';
import 'package:route_hierarchical/client.dart';

main() {
  group('RouteHandle', () {
    Router router;
    Route fooRoute;
    Route fooRoute2;
    RouteHandle routeHandle;

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
                pageTitle: 'something'))
        ..addRoute(name: 'bar', path: '/bar');
      fooRoute = router.findRoute('foo');
      fooRoute2 = router.findRoute('foo.foo2');
      routeHandle = fooRoute.newHandle();
    });

    test('should scope route event subscriptions', () async {
      Map<String, int> counters = {
        'PreEnter': 0,
        'PreLeave': 0,
        'Enter': 0,
        'Leave': 0,
      };

      routeHandle.onPreEnter.listen((_) => counters['PreEnter']++);
      routeHandle.onPreLeave.listen((_) => counters['PreLeave']++);
      routeHandle.onEnter.listen((_) => counters['Enter']++);
      routeHandle.onLeave.listen((_) => counters['Leave']++);

      expect(counters, {'PreEnter': 0, 'PreLeave': 0, 'Enter': 0, 'Leave': 0,});

      await router.route('/foo');
      expect(counters, {'PreEnter': 1, 'PreLeave': 0, 'Enter': 1, 'Leave': 0,});

      await router.route('/bar');
      expect(counters, {'PreEnter': 1, 'PreLeave': 1, 'Enter': 1, 'Leave': 1,});

      routeHandle.discard();
      await router.route('/foo');
      expect(counters, {'PreEnter': 1, 'PreLeave': 1, 'Enter': 1, 'Leave': 1,});
    });

    test('should return valid RouteHandles for child routes', () {
      RouteHandle subRoute = routeHandle.findRoute('foo2');
      expect(subRoute is RouteHandle, isTrue);
      expect(subRoute.name, equals('foo2'));
    });

    test('should support generating new RouteHandle for itself', () {
      RouteHandle cloneHandle = routeHandle.newHandle();
      expect(cloneHandle is RouteHandle, isTrue);
      expect(cloneHandle.name, routeHandle.name);
    });

    test('should support use as a starting route', () async {
      expect(fooRoute2.isActive, isFalse);
      await router.route('/foo2/abc?what=ever', startingFrom: routeHandle);
      expect(fooRoute2.isActive, isTrue);
    });

    group('proxy operations', () {
      setUp(() {
        router.route('/foo/foo2/abc?what=ever');
        routeHandle = fooRoute2.newHandle();
      });

      test('isActive should match route.isActive', () {
        expect(routeHandle.isActive, isTrue);
        expect(routeHandle.isActive, equals(fooRoute2.isActive));
      });

      test('parameters should match route.parameters', () {
        expect(routeHandle.parameters, equals({'fooParam': 'abc'}));
        expect(routeHandle.parameters, equals(fooRoute2.parameters));
      });

      test('query parameters should match route.queryParameters', () {
        expect(routeHandle.queryParameters, equals({'what': 'ever'}));
        expect(routeHandle.queryParameters, equals(fooRoute2.queryParameters));
      });

      test('path should match route.path', () {
        expect(routeHandle.path, equals(fooRoute2.path));
      });

      test('name should match route.name', () {
        expect(routeHandle.name, equals('foo2'));
        expect(routeHandle.name, equals(fooRoute2.name));
      });

      test('parent should match route.parent', () {
        expect(routeHandle.parent, equals(fooRoute));
        expect(routeHandle.parent, equals(fooRoute2.parent));
      });

      test('dontLeaveOnParamChanges should match route.dontLeaveOnParamChanges',
          () {
        expect(routeHandle.dontLeaveOnParamChanges, isTrue);
        expect(routeHandle.dontLeaveOnParamChanges,
            equals(fooRoute2.dontLeaveOnParamChanges));
      });

      test('pageTitle should match route.pageTitle', () {
        expect(routeHandle.pageTitle, 'something');
        expect(routeHandle.pageTitle, equals(fooRoute2.pageTitle));
      });
    });

    group('unsupported operations', () {
      test('should throw if adding a route', () {
        expect(() => routeHandle.addRoute(name: 'baz', path: '/baz'),
            throwsUnsupportedError);
      });

      test('should throw if RouteHandle has already been discarded', () {
        routeHandle.discard();
        expect(() => routeHandle.newHandle(), throwsStateError);
      });
    });
  });
}
