library route.providers.memory_history_test;

import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:route_hierarchical/client.dart';
import 'package:route_hierarchical/history_provider.dart';

import '../util/utils.dart';
import 'common_tests.dart';

main() {
  group('MemoryHistory', () {
    commonProviderTests(() => new Router(historyProvider: new MemoryHistory()));

    group('go', () {
      List<String> urlHistory;
      Router router;

      setUp(() {
        urlHistory = [''];
        router = new Router(
            historyProvider: new MemoryHistory(urlHistory: urlHistory));
      });

      test('should change the current url', () async {
        router.root.addRoute(name: 'articles', path: '/articles');

        expect(urlHistory, equals(['']));
        await router.go('articles', {});
        expect(router.activePath.last.name, equals('articles'));
        expect(urlHistory, equals(['', '/articles']));

        await router.go('articles', {}, replace: true);
        expect(router.activePath.last.name, equals('articles'));
        expect(urlHistory, equals(['', '/articles']));
      });

      test('should encode parameters in the URL', () async {
        router.root.addRoute(name: 'foo', path: '/foo/:param');
        await router.go('foo', {'param': 'something'});
        expect(urlHistory, equals(['', '/foo/something']));
      });

      test('should encode query parameters in the URL', () async {
        router.root.addRoute(name: 'articles', path: '/articles');

        var queryParams = {'foo': 'foo bar', 'bar': '%baz+aux'};
        await router.go('articles', {}, queryParameters: queryParams);
        expect(urlHistory,
            equals(['', '/articles?foo=foo%20bar&bar=%25baz%2Baux']));
      });

      test('should work with hierarchical go', () async {
        router.root
          ..addRoute(
              name: 'a',
              path: '/:foo',
              mount: (child) => child..addRoute(name: 'b', path: '/:bar'));

        var routeA = router.root.findRoute('a');

        await router.go('a.b', {});
        expect(urlHistory, equals(['', '/null/null']));

        await router.go('a.b', {'foo': 'aaaa', 'bar': 'bbbb'});
        expect(urlHistory, equals(['', '/null/null', '/aaaa/bbbb']));

        await router.go('b', {'bar': 'bbbb'}, startingFrom: routeA);
        expect(
            urlHistory, equals(['', '/null/null', '/aaaa/bbbb', '/aaaa/bbbb']));
      });

      test('should attempt to reverse default routes', () async {
        var counters = <String, int>{'aEnter': 0, 'bEnter': 0};
        router.root
          ..addRoute(
              name: 'a',
              defaultRoute: true,
              path: '/:foo',
              enter: (_) => counters['aEnter']++,
              mount: (child) => child
                ..addRoute(
                    name: 'b',
                    defaultRoute: true,
                    path: '/:bar',
                    enter: (_) => counters['bEnter']++));

        expect(counters, {'aEnter': 0, 'bEnter': 0});

        await router.route('');
        expect(counters, {'aEnter': 1, 'bEnter': 1});

        var routeA = router.root.findRoute('a');
        await router.go('b', {'bar': 'bbb'}, startingFrom: routeA);
        expect(urlHistory, equals(['', '/null/bbb']));
      });

      test('should force reload already active routes', () async {
        var counters = <String, int>{'aEnter': 0, 'bEnter': 0};
        router.root
          ..addRoute(
              name: 'a',
              path: '/foo',
              enter: (_) => counters['aEnter']++,
              mount: (child) => child
                ..addRoute(
                    name: 'b',
                    path: '/bar',
                    enter: (_) => counters['bEnter']++));

        expect(counters, {'aEnter': 0, 'bEnter': 0});

        await router.go('a.b', {});
        expect(counters, {'aEnter': 1, 'bEnter': 1});
        await router.go('a.b', {});
        // didn't force reload, so should not change
        expect(counters, {'aEnter': 1, 'bEnter': 1});
        await router.go('a.b', {}, forceReload: true);
        expect(counters, {'aEnter': 2, 'bEnter': 2});
      });
    });

    group('url', () {
      test('should reconstruct url', () async {
        var router = new Router(historyProvider: new MemoryHistory());
        router.root
          ..addRoute(
              name: 'a',
              defaultRoute: true,
              path: '/:foo',
              mount: (child) => child
                ..addRoute(name: 'b', defaultRoute: true, path: '/:bar'));

        var routeA = router.root.findRoute('a');

        await router.route('');
        expect(router.url('a.b'), router.normalizeUrl('/null/null'));
        expect(router.url('a.b', parameters: {'foo': 'aaa'}),
            router.normalizeUrl('/aaa/null'));
        expect(
            router.url('b', parameters: {'bar': 'bbb'}, startingFrom: routeA),
            router.normalizeUrl('/null/bbb'));

        await router.route('/foo/bar');
        expect(router.url('a.b'), router.normalizeUrl('/foo/bar'));
        expect(router.url('a.b', parameters: {'foo': 'aaa'}),
            router.normalizeUrl('/aaa/bar'));
        expect(
            router.url('b', parameters: {'bar': 'bbb'}, startingFrom: routeA),
            router.normalizeUrl('/foo/bbb'));
        expect(
            router.url('b',
                parameters: {'foo': 'aaa', 'bar': 'bbb'}, startingFrom: routeA),
            router.normalizeUrl('/foo/bbb'));

        expect(
            router.url('b',
                parameters: {'bar': 'bbb'},
                queryParameters: {'param1': 'val1'},
                startingFrom: routeA),
            router.normalizeUrl('/foo/bbb?param1=val1'));
      });
    });

    group('activePath', () {
      Router router;

      setUp(() {
        router = new Router(historyProvider: new MemoryHistory());
      });

      test('should correctly identify active path after relative go', () async {
        router.root
          ..addRoute(
              name: 'foo',
              path: '/foo',
              mount: (child) => child
                ..addRoute(
                    name: 'bar',
                    path: '/bar',
                    mount: (child) => child
                      ..addRoute(
                          name: 'baz', path: '/baz', mount: (child) => child))
                ..addRoute(
                    name: 'qux',
                    path: '/qux',
                    mount: (child) => child
                      ..addRoute(
                          name: 'aux', path: '/aux', mount: (child) => child)));

        var strPath =
            (List<Route> path) => path.map((Route r) => r.name).join('.');

        expect(strPath(router.activePath), '');

        await router.route('/foo');
        expect(strPath(router.activePath), 'foo');

        var foo = router.findRoute('foo');
        await router.go('bar', {}, startingFrom: foo);
        expect(strPath(router.activePath), 'foo.bar');
      });

      test(
          'should correctly identify active path after relative go from deeper active path',
          () async {
        router.root
          ..addRoute(
              name: 'foo',
              path: '/foo',
              mount: (child) => child
                ..addRoute(
                    name: 'bar',
                    path: '/bar',
                    mount: (child) => child
                      ..addRoute(
                          name: 'baz', path: '/baz', mount: (child) => child))
                ..addRoute(
                    name: 'qux',
                    path: '/qux',
                    mount: (child) => child
                      ..addRoute(
                          name: 'aux', path: '/aux', mount: (child) => child)));

        var strPath =
            (List<Route> path) => path.map((Route r) => r.name).join('.');

        expect(strPath(router.activePath), '');

        await router.route('/foo/qux/aux');
        expect(strPath(router.activePath), 'foo.qux.aux');

        var foo = router.findRoute('foo');
        await router.go('bar', {}, startingFrom: foo);
        expect(strPath(router.activePath), 'foo.bar');
      });
    });

    group('listen', () {
      group('links', () {
        HistoryProvider history;
        Router router;
        Element toRemove;

        setUp(() {
          history = new MemoryHistory();
          router = new Router(historyProvider: history);
          router.root.addRoute(name: 'foo', path: '/foo', pageTitle: 'Foo');
        });

        tearDown(() {
          if (toRemove != null) {
            toRemove.remove();
            toRemove = null;
          }
        });

        test('it should be called if event triggered on anchor element',
            () async {
          AnchorElement anchor = new AnchorElement();
          anchor.href = router.normalizeUrl('/foo');
          document.body.append(toRemove = anchor);

          router.listen(appRoot: anchor);

          expect(history.pageTitle, equals(''));
          expect(router.findRoute('foo').isActive, isFalse);

          anchor.click();

          await new Future.delayed(Duration.ZERO);
          expect(history.pageTitle, equals('Foo'));
          expect(router.findRoute('foo').isActive, isTrue);
        });

        test(
            'it should be called if event triggered on child of an anchor element',
            () async {
          Element anchorChild = new DivElement();
          AnchorElement anchor = new AnchorElement();
          anchor.href = router.normalizeUrl('/foo');
          anchor.append(anchorChild);
          document.body.append(toRemove = anchor);

          router.listen(appRoot: anchor);

          expect(history.pageTitle, equals(''));
          expect(router.findRoute('foo').isActive, isFalse);

          anchorChild.click();

          await new Future.delayed(Duration.ZERO);
          expect(history.pageTitle, equals('Foo'));
          expect(router.findRoute('foo').isActive, isTrue);
        });
      });
    });

    test('should support history.back', () async {
      List<String> urlHistory = [''];
      MemoryHistory memHistory = new MemoryHistory(urlHistory: urlHistory);
      var router = new Router(historyProvider: memHistory);
      router.root
        ..addRoute(name: 'foo', path: '/foo')
        ..addRoute(name: 'bar', path: '/bar');

      expect(urlHistory, equals(['']));
      await router.go('foo', {});
      expect(urlHistory, equals(['', '/foo']));

      await router.go('bar', {});
      expect(urlHistory, equals(['', '/foo', '/bar']));

      memHistory.back();
      await nextTick();
      expect(urlHistory, equals(['', '/foo']));
    });
  });
}
