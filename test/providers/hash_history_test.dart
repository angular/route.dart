library route.providers.hash_history_test;

import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:route_hierarchical/client.dart';
import 'package:route_hierarchical/history_provider.dart';

import '../util/mocks.dart';
import '../util/utils.dart';
import 'common_tests.dart';

main() {
  group('HashHistory', () {
    commonProviderTests(() => new Router(historyProvider: new HashHistory()));

    group('go', () {
      MockWindow mockWindow;
      Router router;

      setUp(() {
        mockWindow = new MockWindow();
        router = new Router(
            historyProvider: new HashHistory(windowImpl: mockWindow));
      });

      test('should use location.assign/.replace when useFragment=true',
          () async {
        router.root.addRoute(name: 'articles', path: '/articles');

        await router.go('articles', {});
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('#/articles'));

        await router.go('articles', {}, replace: true);
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('#/articles'));
      });

      test('should encode parameters in the URL', () async {
        router.root.addRoute(name: 'foo', path: '/foo/:param');
        await router.go('foo', {'param': 'something'});
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('#/foo/something'));
      });

      test('should encode query parameters in the URL', () async {
        router.root.addRoute(name: 'articles', path: '/articles');

        var queryParams = {'foo': 'foo bar', 'bar': '%baz+aux'};
        await router.go('articles', {}, queryParameters: queryParams);
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last,
            equals('#/articles?foo=foo%20bar&bar=%25baz%2Baux'));
      });

      test('should work with hierarchical go', () async {
        router.root
          ..addRoute(
              name: 'a',
              path: '/:foo',
              mount: (child) => child..addRoute(name: 'b', path: '/:bar'));

        var routeA = router.root.findRoute('a');

        await router.go('a.b', {});
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('#/null/null'));

        await router.go('a.b', {'foo': 'aaaa', 'bar': 'bbbb'});
        expect(mockWindow.history.urlList.length, equals(2));
        expect(mockWindow.history.urlList.last, equals('#/aaaa/bbbb'));

        await router.go('b', {'bar': 'bbbb'}, startingFrom: routeA);
        expect(mockWindow.history.urlList.length, equals(3));
        expect(mockWindow.history.urlList.last, equals('#/aaaa/bbbb'));
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
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('#/null/bbb'));
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

      test('should update page title if the title property is set', () async {
        router.root.addRoute(name: 'foo', path: '/foo', pageTitle: 'Foo');

        await router.go('foo', {});
        verify(mockWindow.document.title = 'Foo');
      });

      test('should not change page title if the title property is not set',
          () async {
        router.root.addRoute(name: 'foo', path: '/foo');

        expect(mockWindow.document.title, equals('page title'));

        await router.go('foo', {});
        expect(mockWindow.document.title, equals('page title'));
      });
    });

    group('url', () {
      test('should reconstruct url', () async {
        var mockWindow = new MockWindow();
        var router = new Router(
            historyProvider: new HashHistory(windowImpl: mockWindow));
        router.root
          ..addRoute(
              name: 'a',
              defaultRoute: true,
              path: '/:foo',
              mount: (child) => child
                ..addRoute(name: 'b', defaultRoute: true, path: '/:bar'));

        var routeA = router.root.findRoute('a');

        await router.route('');
        expect(router.url('a.b'), '#/null/null');
        expect(router.url('a.b', parameters: {'foo': 'aaa'}), '#/aaa/null');
        expect(
            router.url('b', parameters: {'bar': 'bbb'}, startingFrom: routeA),
            '#/null/bbb');

        await router.route('/foo/bar');
        expect(router.url('a.b'), '#/foo/bar');
        expect(router.url('a.b', parameters: {'foo': 'aaa'}), '#/aaa/bar');
        expect(
            router.url('b', parameters: {'bar': 'bbb'}, startingFrom: routeA),
            '#/foo/bbb');
        expect(
            router.url('b',
                parameters: {'foo': 'aaa', 'bar': 'bbb'}, startingFrom: routeA),
            '#/foo/bbb');

        expect(
            router.url('b',
                parameters: {'bar': 'bbb'},
                queryParameters: {'param1': 'val1'},
                startingFrom: routeA),
            '#/foo/bbb?param1=val1');
      });
    });

    group('activePath', () {
      MockWindow mockWindow;
      Router router;

      setUp(() {
        mockWindow = new MockWindow();
        router = new Router(
            historyProvider: new BrowserHistory(windowImpl: mockWindow));
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
      group('fragment', () {
        test('should route current hash on listen', () {
          var mockWindow = new MockWindow();
          when(mockWindow.location.hash).thenReturn('#/foo');
          var router = new Router(
              historyProvider: new HashHistory(windowImpl: mockWindow));
          router.root.addRoute(name: 'foo', path: '/foo');
          router.onRouteStart.listen(expectAsync((RouteStartEvent start) async {
            await start.completed;
            expect(router.findRoute('foo').isActive, isTrue);
          }, count: 1));
          router.listen(ignoreClick: true);
        });

        test('should process url changes for route rejection', () async {
          var mockWindow = new MockWindow();
          var router = new Router(
              historyProvider: new HashHistory(windowImpl: mockWindow));
          router.root
            ..addRoute(
                name: 'foo',
                path: '/foo',
                preEnter: (RoutePreEnterEvent e) {
                  Completer<bool> completer = new Completer();
                  completer.complete(false);
                  return e.allowEnter(completer.future);
                })
            ..addRoute(name: 'bar', path: '/bar');

          router.listen();

          await router.go('bar', {});
          expect(mockWindow.history.urlList.length, equals(1));
          expect(mockWindow.history.urlList.last, equals('#/bar'));

          when(mockWindow.location.hash).thenReturn('#/foo');
          mockWindow.changeHash('#/foo');

          await nextTick();
          expect(mockWindow.history.backCalled, isTrue);
        });
      });

      group('links', () {
        MockWindow mockWindow;
        HistoryProvider history;
        Router router;
        Element toRemove;

        setUp(() {
          mockWindow = new MockWindow();
          history = new HashHistory(windowImpl: mockWindow);
          when(mockWindow.location.hash).thenReturn('#/foo');
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
          anchor.href = '#foo';
          document.body.append(toRemove = anchor);

          router.listen(appRoot: anchor);

          expect(history.pageTitle, equals('page title'));
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
          anchor.href = '#foo';
          anchor.append(anchorChild);
          document.body.append(toRemove = anchor);

          router.listen(appRoot: anchor);

          expect(history.pageTitle, equals('page title'));
          expect(router.findRoute('foo').isActive, isFalse);

          anchorChild.click();

          await new Future.delayed(Duration.ZERO);
          expect(history.pageTitle, equals('Foo'));
          expect(router.findRoute('foo').isActive, isTrue);
        });
      });
    });
  });
}
