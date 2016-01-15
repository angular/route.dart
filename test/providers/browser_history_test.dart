library route.providers.browser_history_test;

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
  group('BrowserHistory', () {
    commonProviderTests(
        () => new Router(historyProvider: new BrowserHistory()));

    group('go', () {
      MockWindow mockWindow;
      Router router;

      setUp(() {
        mockWindow = new MockWindow();
        router = new Router(
            historyProvider: new BrowserHistory(windowImpl: mockWindow));
      });

      test('should use history.push/.replaceState when using BrowserHistory',
          () async {
        router.root.addRoute(name: 'articles', path: '/articles');

        await router.go('articles', {});
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('/articles'));

        await router.go('articles', {}, replace: true);
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('/articles'));
      });

      test('should encode parameters in the URL', () async {
        router.root.addRoute(name: 'foo', path: '/foo/:param');
        await router.go('foo', {'param': 'something'});
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('/foo/something'));
      });

      test('should encode query parameters in the URL', () async {
        router.root.addRoute(name: 'articles', path: '/articles');

        var queryParams = {'foo': 'foo bar', 'bar': '%baz+aux'};
        await router.go('articles', {}, queryParameters: queryParams);
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last,
            equals('/articles?foo=foo%20bar&bar=%25baz%2Baux'));
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
        expect(mockWindow.history.urlList.last, equals('/null/null'));

        await router.go('a.b', {'foo': 'aaaa', 'bar': 'bbbb'});
        expect(mockWindow.history.urlList.length, equals(2));
        expect(mockWindow.history.urlList.last, equals('/aaaa/bbbb'));

        await router.go('b', {'bar': 'bbbb'}, startingFrom: routeA);
        expect(mockWindow.history.urlList.length, equals(3));
        expect(mockWindow.history.urlList.last, equals('/aaaa/bbbb'));
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
        expect(mockWindow.history.urlList.last, equals('/null/bbb'));
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
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('/foo'));
      });

      test('should not change page title if the title property is not set',
          () async {
        router.root.addRoute(name: 'foo', path: '/foo');

        await router.go('foo', {});
        verifyNever(mockWindow.document.title = 'Foo');
        expect(mockWindow.history.urlList.length, equals(1));
        expect(mockWindow.history.urlList.last, equals('/foo'));
      });
    });

    group('url', () {
      test('should reconstruct url', () async {
        var mockWindow = new MockWindow();
        var router = new Router(
            historyProvider: new BrowserHistory(windowImpl: mockWindow));
        router.root
          ..addRoute(
              name: 'a',
              defaultRoute: true,
              path: '/:foo',
              mount: (child) => child
                ..addRoute(name: 'b', defaultRoute: true, path: '/:bar'));

        var routeA = router.root.findRoute('a');

        await router.route('');
        expect(router.url('a.b'), '/null/null');
        expect(router.url('a.b', parameters: {'foo': 'aaa'}), '/aaa/null');
        expect(
            router.url('b', parameters: {'bar': 'bbb'}, startingFrom: routeA),
            '/null/bbb');

        await router.route('/foo/bar');
        expect(router.url('a.b'), '/foo/bar');
        expect(router.url('a.b', parameters: {'foo': 'aaa'}), '/aaa/bar');
        expect(
            router.url('b', parameters: {'bar': 'bbb'}, startingFrom: routeA),
            '/foo/bbb');
        expect(
            router.url('b',
                parameters: {'foo': 'aaa', 'bar': 'bbb'}, startingFrom: routeA),
            '/foo/bbb');

        expect(
            router.url('b',
                parameters: {'bar': 'bbb'},
                queryParameters: {'param1': 'val1'},
                startingFrom: routeA),
            '/foo/bbb?param1=val1');
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
      group('pushState', () {
        testInit(mockWindow, [count = 1]) {
          when(mockWindow.location.pathname).thenReturn('/hello');
          when(mockWindow.location.search).thenReturn('?foo=bar&baz=bat');
          var router = new Router(
              historyProvider: new BrowserHistory(windowImpl: mockWindow));
          router.root.addRoute(name: 'hello', path: '/hello');
          router.onRouteStart.listen(expectAsync((RouteStartEvent start) async {
            await start.completed;
            expect(router.findRoute('hello').isActive, isTrue);
            expect(router.findRoute('hello').queryParameters['baz'], 'bat');
            expect(router.findRoute('hello').queryParameters['foo'], 'bar');
          }, count: count));
          router.listen(ignoreClick: true);
        }

        test('should route current path on listen with pop', () {
          var mockWindow = new MockWindow();
          var mockPopStateController = new StreamController<Event>(sync: true);
          when(mockWindow.onPopState).thenReturn(mockPopStateController.stream);
          testInit(mockWindow, 2);
          mockPopStateController.add(null);
        });

        test('should route current path on listen without pop', () {
          var mockWindow = new MockWindow();
          var mockPopStateController = new StreamController<Event>(sync: true);
          when(mockWindow.onPopState).thenReturn(mockPopStateController.stream);
          testInit(mockWindow);
        });

        test('should process url changes for route rejection', () async {
          var mockWindow = new MockWindow();
          var router = new Router(
              historyProvider: new BrowserHistory(windowImpl: mockWindow));
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
          expect(mockWindow.history.urlList.last, equals('/bar'));

          when(mockWindow.location.pathname).thenReturn('');
          when(mockWindow.location.search).thenReturn('');
          when(mockWindow.location.hash).thenReturn('/foo');
          mockWindow.changeHash('/foo');

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
          history = new BrowserHistory(windowImpl: mockWindow);
          var mockPopStateController = new StreamController<Event>(sync: true);
          when(mockWindow.onPopState).thenReturn(mockPopStateController.stream);
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
          anchor.href = '/foo';
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
          anchor.href = '/foo';
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
