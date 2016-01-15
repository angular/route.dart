// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library route.providers.common_tests;

import 'dart:async';

import 'package:test/test.dart';
import 'package:route_hierarchical/client.dart';

import '../util/mocks.dart';

typedef Router RouterFactory();

commonProviderTests(RouterFactory routerFactory) {
  Router router;

  setUp(() {
    router = routerFactory();
  });

  test('paths are routed to routes added with addRoute', () {
    router.root.addRoute(
        name: 'foo',
        path: '/foo',
        enter: expectAsync((RouteEvent e) {
          expect(e.path, '/foo');
          expect(router.root.findRoute('foo').isActive, isTrue);
          expect(router.isUrlActive('/foo'), isTrue);
        }));
    return router.route('/foo');
  });

  group('error states', () {
    test('go method should throw if supplied an invalid route', () {
      expect(() => router.go('foo', {}), throwsStateError);
    });

    test('url method should throw if supplied an invalid route', () {
      expect(() => router.url('foo'), throwsStateError);
    });

    test('listen method should throw if executed more than once', () {
      router.listen(ignoreClick: true);
      expect(() => router.listen(ignoreClick: true), throwsStateError);
    });
  });

  group('invalid routes', () {
    test('should throw if route has no name', () {
      expect(() => router.root.addRoute(path: '/foo'), throwsArgumentError);
    });

    test('should throw if route name contains path separators', () {
      expect(() => router.root.addRoute(name: 'foo.bar', path: '/foo'),
          throwsArgumentError);
    });

    test('should throw if route name matches an existing route', () {
      router.root.addRoute(name: 'foo', path: '/foo');
      expect(() => router.root.addRoute(name: 'foo', path: '/foo'),
          throwsArgumentError);
    });
  });

  group('use a longer path first', () {
    test('add a longer path first', () {
      router.root
        ..addRoute(
            name: 'foobar',
            path: '/foo/bar',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/foo/bar');
              expect(router.root.findRoute('foobar').isActive, isTrue);
              expect(router.isUrlActive('/foo/bar'), isTrue);
            }))
        ..addRoute(
            name: 'foo',
            path: '/foo',
            enter: (e) => fail('should invoke /foo/bar'));
      return router.route('/foo/bar');
    });

    test('add a longer path last', () {
      router.root
        ..addRoute(
            name: 'foo',
            path: '/foo',
            enter: (e) => fail('should invoke /foo/bar'))
        ..addRoute(
            name: 'foobar',
            path: '/foo/bar',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/foo/bar');
              expect(router.root.findRoute('foobar').isActive, isTrue);
              expect(router.isUrlActive('/foo/bar'), isTrue);
            }));
      return router.route('/foo/bar');
    });

    test('add paths with a param', () {
      router.root
        ..addRoute(
            name: 'foo',
            path: '/foo',
            enter: (e) => fail('should invoke /foo/bar'))
        ..addRoute(
            name: 'fooparam',
            path: '/foo/:param',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/foo/bar');
              expect(router.root.findRoute('fooparam').isActive, isTrue);
              expect(router.isUrlActive('/foo/bar'), isTrue);
            }));
      return router.route('/foo/bar');
    });

    test('add paths with a parameterized parent', () {
      router.root
        ..addRoute(
            name: 'paramaddress',
            path: '/:zzzzzz/address',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/foo/address');
              expect(router.root.findRoute('paramaddress').isActive, isTrue);
              expect(router.isUrlActive('/foo/address'), isTrue);
            }))
        ..addRoute(
            name: 'param_add',
            path: '/:aaaaaa/add',
            enter: (e) => fail('should invoke /foo/address'));
      return router.route('/foo/address');
    });

    test('add paths with a first param and one without', () {
      router.root
        ..addRoute(
            name: 'fooparam',
            path: '/:param/foo',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/bar/foo');
              expect(router.root.findRoute('fooparam').isActive, isTrue);
              expect(router.isUrlActive('/bar/foo'), isTrue);
            }))
        ..addRoute(
            name: 'bar',
            path: '/bar',
            enter: (e) => fail('should enter fooparam'));
      return router.route('/bar/foo');
    });

    test('add paths with a first param and one without 2', () {
      router.root
        ..addRoute(
            name: 'paramfoo',
            path: '/:param/foo',
            enter: (e) => fail('should enter barfoo'))
        ..addRoute(
            name: 'barfoo',
            path: '/bar/foo',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/bar/foo');
              expect(router.root.findRoute('barfoo').isActive, isTrue);
              expect(router.isUrlActive('/bar/foo'), isTrue);
            }));
      return router.route('/bar/foo');
    });

    test('add paths with a second param and one without', () {
      router.root
        ..addRoute(
            name: 'bazparamfoo',
            path: '/baz/:param/foo',
            enter: (e) => fail('should enter bazbarfoo'))
        ..addRoute(
            name: 'bazbarfoo',
            path: '/baz/bar/foo',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/baz/bar/foo');
              expect(router.root.findRoute('bazbarfoo').isActive, isTrue);
              expect(router.isUrlActive('/baz/bar/foo'), isTrue);
            }));
      return router.route('/baz/bar/foo');
    });

    test('add paths with a first param and a second param', () {
      router.root
        ..addRoute(
            name: 'parambarfoo',
            path: '/:param/bar/foo',
            enter: (e) => fail('should enter bazparamfoo'))
        ..addRoute(
            name: 'bazparamfoo',
            path: '/baz/:param/foo',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/baz/bar/foo');
              expect(router.root.findRoute('bazparamfoo').isActive, isTrue);
              expect(router.isUrlActive('/baz/bar/foo'), isTrue);
            }));
      return router.route('/baz/bar/foo');
    });

    test('add paths with two params and a param', () {
      router.root
        ..addRoute(
            name: 'param1param2foo',
            path: '/:param1/:param2/foo',
            enter: (e) => fail('should enter bazparamfoo'))
        ..addRoute(
            name: 'param1barfoo',
            path: '/:param1/bar/foo',
            enter: expectAsync((RouteEvent e) {
              expect(e.path, '/baz/bar/foo');
              expect(router.root.findRoute('param1barfoo').isActive, isTrue);
              expect(router.isUrlActive('/baz/bar/foo'), isTrue);
            }));
      return router.route('/baz/bar/foo');
    });
  });

  group('hierarchical routing', () {
    void _testParentChild(Pattern parentPath, Pattern childPath,
        String expectedParentPath, String expectedChildPath, String testPath) {
      router.root.addRoute(
          name: 'parent',
          path: parentPath,
          enter: expectAsync((RouteEvent e) {
            expect(e.path, expectedParentPath);
            expect(e.route, isNotNull);
            expect(e.route.name, 'parent');
          }),
          mount: (Route child) {
            child.addRoute(
                name: 'child',
                path: childPath,
                enter: expectAsync((RouteEvent e) {
                  expect(e.path, expectedChildPath);
                }));
          });
      router.route(testPath);
    }

    test('child router with Strings', () {
      _testParentChild('/foo', '/bar', '/foo', '/bar', '/foo/bar');
    });
  });

  group('Routable', () {
    test('should configure routes when mounted', () {
      MockRoutable routable = new MockRoutable();
      expect(routable.routesConfigured, isFalse);
      router.root.addRoute(name: 'foo', path: '/foo', mount: routable);
      expect(routable.routesConfigured, isTrue);
    });
  });

  group('reload', () {
    Map counters;

    setUp(() {
      counters = {'fooLeave': 0, 'fooEnter': 0, 'barLeave': 0, 'barEnter': 0,};

      router.root
        ..addRoute(
            name: 'foo',
            path: '/:foo',
            leave: (_) => counters['fooLeave']++,
            enter: (_) => counters['fooEnter']++,
            mount: (r) => r.addRoute(
                name: 'bar',
                path: '/:bar',
                leave: (_) => counters['barLeave']++,
                enter: (_) => counters['barEnter']++));
    });

    test('should not reload when no active path', () async {
      await router.reload();
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 0, 'barLeave': 0, 'barEnter': 0});
    });

    test('should reload currently active route', () async {
      await router.route('/123');
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 1, 'barLeave': 0, 'barEnter': 0,});
      await router.reload();
      expect(counters,
          {'fooLeave': 1, 'fooEnter': 2, 'barLeave': 0, 'barEnter': 0,});
      expect(router.findRoute('foo').parameters['foo'], '123');
    });

    test('should reload currently active route from startingFrom', () async {
      await router.route('/123/321');
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 1, 'barLeave': 0, 'barEnter': 1,});
      await router.reload(startingFrom: router.findRoute('foo'));
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 1, 'barLeave': 1, 'barEnter': 2,});
      expect(router.findRoute('foo').parameters['foo'], '123');
      expect(router.findRoute('foo.bar').parameters['bar'], '321');
    });

    test('should preserve param values on reload', () async {
      await router.route('/123/321');
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 1, 'barLeave': 0, 'barEnter': 1,});
      await router.reload();
      expect(counters,
          {'fooLeave': 1, 'fooEnter': 2, 'barLeave': 1, 'barEnter': 2,});
      expect(router.findRoute('foo').parameters['foo'], '123');
      expect(router.findRoute('foo.bar').parameters['bar'], '321');
    });

    test('should preserve query param values on reload', () async {
      await router.route('/123?foo=bar&blah=blah');
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 1, 'barLeave': 0, 'barEnter': 0});
      expect(router.findRoute('foo').queryParameters,
          {'foo': 'bar', 'blah': 'blah',});
      await router.reload();
      expect(router.findRoute('foo').queryParameters,
          {'foo': 'bar', 'blah': 'blah',});
    });

    test('should preserve query param values on reload from the middle',
        () async {
      await router.route('/123/321?foo=bar&blah=blah');
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 1, 'barLeave': 0, 'barEnter': 1,});
      expect(router.findRoute('foo').queryParameters,
          {'foo': 'bar', 'blah': 'blah',});
      await router.reload(startingFrom: router.findRoute('foo'));
      expect(counters,
          {'fooLeave': 0, 'fooEnter': 1, 'barLeave': 1, 'barEnter': 2,});
      expect(router.findRoute('foo').queryParameters,
          {'foo': 'bar', 'blah': 'blah',});
      expect(router.findRoute('foo').parameters['foo'], '123');
      expect(router.findRoute('foo.bar').parameters['bar'], '321');
    });
  });

  group('leave', () {
    test('should leave previous route and enter new', () async {
      var counters = <String, int>{
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0,
        'bazPreEnter': 0,
        'bazPreLeave': 0,
        'bazEnter': 0,
        'bazLeave': 0
      };
      router.root
        ..addRoute(
            path: '/foo',
            name: 'foo',
            preEnter: (_) => counters['fooPreEnter']++,
            preLeave: (_) => counters['fooPreLeave']++,
            enter: (_) => counters['fooEnter']++,
            leave: (_) => counters['fooLeave']++,
            watchQueryParameters: [],
            mount: (Route route) => route
              ..addRoute(
                  path: '/bar',
                  name: 'bar',
                  preEnter: (_) => counters['barPreEnter']++,
                  preLeave: (_) => counters['barPreLeave']++,
                  enter: (_) => counters['barEnter']++,
                  leave: (_) => counters['barLeave']++)
              ..addRoute(
                  path: '/baz',
                  name: 'baz',
                  preEnter: (_) => counters['bazPreEnter']++,
                  preLeave: (_) => counters['bazPreLeave']++,
                  enter: (_) => counters['bazEnter']++,
                  leave: (_) => counters['bazLeave']++,
                  watchQueryParameters: ['baz.blah']));

      expect(counters, {
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0,
        'bazPreEnter': 0,
        'bazPreLeave': 0,
        'bazEnter': 0,
        'bazLeave': 0
      });
      await router.route('/foo/bar');
      expect(counters, {
        'fooPreEnter': 1,
        'fooPreLeave': 0,
        'fooEnter': 1,
        'fooLeave': 0,
        'barPreEnter': 1,
        'barPreLeave': 0,
        'barEnter': 1,
        'barLeave': 0,
        'bazPreEnter': 0,
        'bazPreLeave': 0,
        'bazEnter': 0,
        'bazLeave': 0
      });

      await router.route('/foo/baz');
      expect(counters, {
        'fooPreEnter': 1,
        'fooPreLeave': 0,
        'fooEnter': 1,
        'fooLeave': 0,
        'barPreEnter': 1,
        'barPreLeave': 1,
        'barEnter': 1,
        'barLeave': 1,
        'bazPreEnter': 1,
        'bazPreLeave': 0,
        'bazEnter': 1,
        'bazLeave': 0
      });

      await router.route('/foo/baz?baz.blah=meme');
      expect(counters, {
        'fooPreEnter': 1,
        'fooPreLeave': 0,
        'fooEnter': 1,
        'fooLeave': 0,
        'barPreEnter': 1,
        'barPreLeave': 1,
        'barEnter': 1,
        'barLeave': 1,
        'bazPreEnter': 2,
        'bazPreLeave': 1,
        'bazEnter': 2,
        'bazLeave': 1
      });
    });

    test('should leave starting from child to parent', () async {
      var log = [];
      void loggingLeaveHandler(RouteLeaveEvent r) {
        log.add(r.route.name);
      }

      router.root
        ..addRoute(
            path: '/foo',
            name: 'foo',
            leave: loggingLeaveHandler,
            mount: (Route route) => route
              ..addRoute(
                  path: '/bar',
                  name: 'bar',
                  leave: loggingLeaveHandler,
                  mount: (Route route) => route
                    ..addRoute(
                        path: '/baz',
                        name: 'baz',
                        leave: loggingLeaveHandler)));

      await router.route('/foo/bar/baz');
      expect(log, []);

      await router.route('');
      expect(log, ['baz', 'bar', 'foo']);
    });

    test('should leave active child route when routed to parent route only',
        () async {
      router.root
        ..addRoute(
            path: '/foo',
            name: 'foo',
            mount: (Route route) => route..addRoute(path: '/bar', name: 'bar'));

      await router.route('/foo/bar');
      expect(router.activePath.map((r) => r.name), ['foo', 'bar']);
      await router.route('/foo');
      expect(router.activePath.map((r) => r.name), ['foo']);
    });

    void _testAllowLeave(bool allowLeave) {
      var completer = new Completer<bool>();
      bool barEntered = false;
      bool bazEntered = false;

      router.root
        ..addRoute(
            name: 'foo',
            path: '/foo',
            mount: (Route child) => child
              ..addRoute(
                  name: 'bar',
                  path: '/bar',
                  enter: (RouteEnterEvent e) => barEntered = true,
                  preLeave: (RoutePreLeaveEvent e) =>
                      e.allowLeave(completer.future))
              ..addRoute(
                  name: 'baz',
                  path: '/baz',
                  enter: (RouteEnterEvent e) => bazEntered = true));

      router.route('/foo/bar').then(expectAsync((_) {
        expect(barEntered, true);
        expect(bazEntered, false);
        router.route('/foo/baz').then(expectAsync((_) {
          expect(bazEntered, allowLeave);
        }));
        completer.complete(allowLeave);
      }));
    }

    test('should allow navigation', () {
      _testAllowLeave(true);
    });

    test('should veto navigation', () {
      _testAllowLeave(false);
    });
  });

  group('preEnter', () {
    void _testAllowEnter(bool allowEnter) {
      var completer = new Completer<bool>();
      bool barEntered = false;

      router.root
        ..addRoute(
            name: 'foo',
            path: '/foo',
            mount: (Route child) => child
              ..addRoute(
                  name: 'bar',
                  path: '/bar',
                  enter: (RouteEnterEvent e) => barEntered = true,
                  preEnter: (RoutePreEnterEvent e) =>
                      e.allowEnter(completer.future)));

      router.route('/foo/bar').then(expectAsync((_) {
        expect(barEntered, allowEnter);
      }));
      completer.complete(allowEnter);
    }

    test('should allow navigation', () {
      _testAllowEnter(true);
    });

    test('should veto navigation', () {
      _testAllowEnter(false);
    });

    test(
        'should leave on parameters changes when dontLeaveOnParamChanges is false (default)',
        () async {
      var counters = <String, int>{
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      };
      router.root
        ..addRoute(
            path: r'/foo/:param',
            name: 'foo',
            preEnter: (_) => counters['fooPreEnter']++,
            preLeave: (_) => counters['fooPreLeave']++,
            enter: (_) => counters['fooEnter']++,
            leave: (_) => counters['fooLeave']++)
        ..addRoute(
            path: '/bar',
            name: 'bar',
            preEnter: (_) => counters['barPreEnter']++,
            preLeave: (_) => counters['barPreLeave']++,
            enter: (_) => counters['barEnter']++,
            leave: (_) => counters['barLeave']++);

      expect(counters, {
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      expect(router.findRoute('foo').dontLeaveOnParamChanges, false);

      await router.route('/foo/bar');
      expect(counters, {
        'fooPreEnter': 1, // +1
        'fooPreLeave': 0,
        'fooEnter': 1, // +1
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/foo/bar');
      expect(counters, {
        'fooPreEnter': 1,
        'fooPreLeave': 0,
        'fooEnter': 1,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/foo/baz');
      expect(counters, {
        'fooPreEnter': 2, // +1
        'fooPreLeave': 1, // +1
        'fooEnter': 2, // +1
        'fooLeave': 1, // +1
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/bar');
      expect(counters, {
        'fooPreEnter': 2,
        'fooPreLeave': 2, // +1
        'fooEnter': 2,
        'fooLeave': 2, // +1
        'barPreEnter': 1, // +1
        'barPreLeave': 0,
        'barEnter': 1, // +1
        'barLeave': 0
      });
    });

    test(
        'should not leave on parameter changes when dontLeaveOnParamChanges is true',
        () async {
      var counters = <String, int>{
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      };
      router.root
        ..addRoute(
            path: r'/foo/:param',
            name: 'foo',
            preEnter: (_) => counters['fooPreEnter']++,
            preLeave: (_) => counters['fooPreLeave']++,
            enter: (_) => counters['fooEnter']++,
            leave: (_) => counters['fooLeave']++,
            dontLeaveOnParamChanges: true)
        ..addRoute(
            path: '/bar',
            name: 'bar',
            preEnter: (_) => counters['barPreEnter']++,
            preLeave: (_) => counters['barPreLeave']++,
            enter: (_) => counters['barEnter']++,
            leave: (_) => counters['barLeave']++);

      expect(counters, {
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/foo/bar');
      expect(counters, {
        'fooPreEnter': 1, // +1
        'fooPreLeave': 0,
        'fooEnter': 1, // +1
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/foo/bar');
      expect(counters, {
        'fooPreEnter': 1,
        'fooPreLeave': 0,
        'fooEnter': 1,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/foo/baz');
      expect(counters, {
        'fooPreEnter': 2, // +1
        'fooPreLeave': 0,
        'fooEnter': 2, // +1
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/bar');
      expect(counters, {
        'fooPreEnter': 2,
        'fooPreLeave': 1, // +1
        'fooEnter': 2,
        'fooLeave': 1, // +1
        'barPreEnter': 1, // +1
        'barPreLeave': 0,
        'barEnter': 1, // +1
        'barLeave': 0
      });
    });

    test('should not leave leaving when on preEnter fails', () async {
      var counters = <String, int>{
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      };
      router.root
        ..addRoute(
            path: r'/foo',
            name: 'foo',
            preEnter: (_) => counters['fooPreEnter']++,
            preLeave: (_) => counters['fooPreLeave']++,
            enter: (_) => counters['fooEnter']++,
            leave: (_) => counters['fooLeave']++)
        ..addRoute(
            path: '/bar',
            name: 'bar',
            preEnter: (RoutePreEnterEvent e) {
              counters['barPreEnter']++;
              e.allowEnter(new Future<bool>.value(false));
            },
            preLeave: (_) => counters['barPreLeave']++,
            enter: (_) => counters['barEnter']++,
            leave: (_) => counters['barLeave']++);

      expect(counters, {
        'fooPreEnter': 0,
        'fooPreLeave': 0,
        'fooEnter': 0,
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/foo');
      expect(counters, {
        'fooPreEnter': 1, // +1
        'fooPreLeave': 0,
        'fooEnter': 1, // +1
        'fooLeave': 0,
        'barPreEnter': 0,
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });

      await router.route('/bar');
      expect(counters, {
        'fooPreEnter': 1,
        'fooPreLeave': 1, // +1
        'fooEnter': 1,
        'fooLeave': 0, // can't leave
        'barPreEnter': 1, // +1, enter but don't proceed
        'barPreLeave': 0,
        'barEnter': 0,
        'barLeave': 0
      });
    });
  });

  group('Default route', () {
    void _testHeadTail(String path, String expectFoo, String expectBar) {
      router.root
        ..addRoute(
            name: 'foo',
            path: '/foo',
            defaultRoute: true,
            enter: expectAsync((RouteEvent e) {
              expect(e.path, expectFoo);
            }),
            mount: (child) => child
              ..addRoute(
                  name: 'bar',
                  path: '/bar',
                  defaultRoute: true,
                  enter: expectAsync(
                      (RouteEvent e) => expect(e.path, expectBar))));

      router.route(path);
    }

    test('should calculate head/tail of empty route', () {
      _testHeadTail('', '', '');
    });

    test('should calculate head/tail of partial route', () {
      _testHeadTail('/foo', '/foo', '');
    });

    test('should calculate head/tail of a route', () {
      _testHeadTail('/foo/bar', '/foo', '/bar');
    });

    test('should calculate head/tail of an invalid parent route', () {
      _testHeadTail('/garbage/bar', '', '');
    });

    test('should calculate head/tail of an invalid child route', () {
      _testHeadTail('/foo/garbage', '/foo', '');
    });

    test('should follow default routes', () async {
      var counters = <String, int>{
        'list_entered': 0,
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      };

      router.root
        ..addRoute(
            name: 'articles',
            path: '/articles',
            defaultRoute: true,
            enter: (_) => counters['list_entered']++)
        ..addRoute(
            name: 'article',
            path: '/article/123',
            enter: (_) => counters['article_123_entered']++,
            mount: (Route child) => child
              ..addRoute(
                  name: 'viewArticles',
                  path: '/view',
                  defaultRoute: true,
                  enter: (_) => counters['article_123_view_entered']++)
              ..addRoute(
                  name: 'editArticles',
                  path: '/edit',
                  enter: (_) => counters['article_123_edit_entered']++));

      await router.route('');
      expect(counters, {
        'list_entered': 1, // default to list
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      });
      await router.route('/articles');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      });
      await router.route('/article/123');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 1,
        'article_123_view_entered': 1, // default to view
        'article_123_edit_entered': 0
      });
      await router.route('/article/123/view');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 1,
        'article_123_view_entered': 2,
        'article_123_edit_entered': 0
      });
      await router.route('/article/123/edit');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 1,
        'article_123_view_entered': 2,
        'article_123_edit_entered': 1
      });
    });

    test('should follow first defined default routes if multiple exist',
        () async {
      var counters = <String, int>{
        'list_entered': 0,
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      };

      router.root
        ..addRoute(
            name: 'articles',
            path: '/articles',
            defaultRoute: true,
            enter: (_) => counters['list_entered']++)
        ..addRoute(
            name: 'article',
            path: '/article/123',
            defaultRoute: true,
            enter: (_) => counters['article_123_entered']++,
            mount: (Route child) => child
              ..addRoute(
                  name: 'viewArticles',
                  path: '/view',
                  defaultRoute: true,
                  enter: (_) => counters['article_123_view_entered']++)
              ..addRoute(
                  name: 'editArticles',
                  path: '/edit',
                  defaultRoute: true,
                  enter: (_) => counters['article_123_edit_entered']++));

      await router.route('');
      expect(counters, {
        'list_entered': 1, // default to list
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      });
      await router.route('/articles');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      });
      await router.route('/article/123');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 1,
        'article_123_view_entered': 1, // default to view
        'article_123_edit_entered': 0
      });
      await router.route('/article/123/view');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 1,
        'article_123_view_entered': 2,
        'article_123_edit_entered': 0
      });
      await router.route('/article/123/edit');
      expect(counters, {
        'list_entered': 2,
        'article_123_entered': 1,
        'article_123_view_entered': 2,
        'article_123_edit_entered': 1
      });
    });

    test(
        'should follow first defined default routes if multiple exist (with reversed defaults)',
        () async {
      var counters = <String, int>{
        'list_entered': 0,
        'article_123_entered': 0,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 0
      };

      router.root
        ..addRoute(
            name: 'article',
            path: '/article/123',
            defaultRoute: true,
            enter: (_) => counters['article_123_entered']++,
            mount: (Route child) => child
              ..addRoute(
                  name: 'editArticles',
                  path: '/edit',
                  defaultRoute: true,
                  enter: (_) => counters['article_123_edit_entered']++)
              ..addRoute(
                  name: 'viewArticles',
                  path: '/view',
                  defaultRoute: true,
                  enter: (_) => counters['article_123_view_entered']++))
        ..addRoute(
            name: 'articles',
            path: '/articles',
            defaultRoute: true,
            enter: (_) => counters['list_entered']++);

      await router.route('');
      expect(counters, {
        'list_entered': 0,
        'article_123_entered': 1, // default to article_123
        'article_123_view_entered': 0,
        'article_123_edit_entered': 1 // default to edit
      });
      await router.route('/articles');
      expect(counters, {
        'list_entered': 1,
        'article_123_entered': 1,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 1
      });
      await router.route('/article/123');
      expect(counters, {
        'list_entered': 1,
        'article_123_entered': 2,
        'article_123_view_entered': 0,
        'article_123_edit_entered': 2 // default to edit
      });
      await router.route('/article/123/view');
      expect(counters, {
        'list_entered': 1,
        'article_123_entered': 2,
        'article_123_view_entered': 1,
        'article_123_edit_entered': 2
      });
      await router.route('/article/123/edit');
      expect(counters, {
        'list_entered': 1,
        'article_123_entered': 2,
        'article_123_view_entered': 1,
        'article_123_edit_entered': 3
      });
    });
  });

  group('findRoute', () {
    test('should return correct routes', () {
      Route routeFoo, routeBar, routeBaz, routeQux, routeAux;

      router.root
        ..addRoute(
            name: 'foo',
            path: '/:foo',
            mount: (child) => routeFoo = child
              ..addRoute(
                  name: 'bar',
                  path: '/:bar',
                  mount: (child) => routeBar = child
                    ..addRoute(
                        name: 'baz',
                        path: '/:baz',
                        mount: (child) => routeBaz = child))
              ..addRoute(
                  name: 'qux',
                  path: '/:qux',
                  mount: (child) => routeQux = child
                    ..addRoute(
                        name: 'aux',
                        path: '/:aux',
                        mount: (child) => routeAux = child)));

      expect(router.root.findRoute('foo'), same(routeFoo));
      expect(router.root.findRoute('foo.bar'), same(routeBar));
      expect(routeFoo.findRoute('bar'), same(routeBar));
      expect(router.root.findRoute('foo.bar.baz'), same(routeBaz));
      expect(router.root.findRoute('foo.qux'), same(routeQux));
      expect(router.root.findRoute('foo.qux.aux'), same(routeAux));
      expect(routeQux.findRoute('aux'), same(routeAux));
      expect(routeFoo.findRoute('qux.aux'), same(routeAux));

      expect(router.root.findRoute('baz'), isNull);
      expect(router.root.findRoute('foo.baz'), isNull);
    });
  });

  group('route', () {
    group('query params', () {
      test('should parse query', () {
        router.root
          ..addRoute(
              name: 'foo',
              path: '/:foo',
              enter: expectAsync((RouteEvent e) {
                expect(e.parameters, {'foo': '123',});
                expect(e.queryParameters, {'a': 'b', 'b': '', 'c': 'foo bar'});
              }));

        router.route('/123?a=b&b=&c=foo%20bar');
      });

      test('should not reload when unwatched query param changes', () async {
        var counters = {'fooLeave': 0, 'fooEnter': 0,};
        router.root
          ..addRoute(
              name: 'foo',
              path: '/:foo',
              watchQueryParameters: ['bar'],
              leave: (_) => counters['fooLeave']++,
              enter: (_) => counters['fooEnter']++);

        await router.route('/123');
        expect(counters, {'fooLeave': 0, 'fooEnter': 1,});
        await router.route('/123?foo=bar');
        expect(counters, {'fooLeave': 0, 'fooEnter': 1,});
      });

      test('should reload when watched query param changes', () async {
        var counters = {'fooLeave': 0, 'fooEnter': 0,};
        router.root
          ..addRoute(
              name: 'foo',
              path: '/:foo',
              watchQueryParameters: ['foo'],
              leave: (_) => counters['fooLeave']++,
              enter: (_) => counters['fooEnter']++);

        await router.route('/123');
        expect(counters, {'fooLeave': 0, 'fooEnter': 1,});
        await router.route('/123?foo=bar');
        expect(counters, {'fooLeave': 1, 'fooEnter': 2,});
      });

      test('should match pattern for watched query params', () async {
        var counters = {'fooLeave': 0, 'fooEnter': 0,};
        router.root
          ..addRoute(
              name: 'foo',
              path: '/:foo',
              watchQueryParameters: [new RegExp(r'^foo$')],
              leave: (_) => counters['fooLeave']++,
              enter: (_) => counters['fooEnter']++);

        await router.route('/123');
        expect(counters, {'fooLeave': 0, 'fooEnter': 1,});
        await router.route('/123?foo=bar');
        expect(counters, {'fooLeave': 1, 'fooEnter': 2,});
      });
    });

    group('isActive', () {
      test('should correctly identify active/inactive routes', () async {
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

        expect(r(router, 'foo').isActive, false);
        expect(r(router, 'foo.bar').isActive, false);
        expect(r(router, 'foo.bar.baz').isActive, false);
        expect(r(router, 'foo.qux').isActive, false);

        expect(router.isUrlActive('/foo'), isFalse);
        expect(router.isUrlActive('/foo/bar'), isFalse);
        expect(router.isUrlActive('/foo/bar/baz'), isFalse);
        expect(router.isUrlActive('/foo/qux'), isFalse);

        await router.route('/foo');
        expect(r(router, 'foo').isActive, true);
        expect(r(router, 'foo.bar').isActive, false);
        expect(r(router, 'foo.bar.baz').isActive, false);
        expect(r(router, 'foo.qux').isActive, false);

        expect(router.isUrlActive('/foo'), isTrue);
        expect(router.isUrlActive('/foo/bar'), isFalse);
        expect(router.isUrlActive('/foo/bar/baz'), isFalse);
        expect(router.isUrlActive('/foo/qux'), isFalse);

        await router.route('/foo/qux');
        expect(r(router, 'foo').isActive, true);
        expect(r(router, 'foo.bar').isActive, false);
        expect(r(router, 'foo.bar.baz').isActive, false);
        expect(r(router, 'foo.qux').isActive, true);

        expect(router.isUrlActive('/foo'), isTrue);
        expect(router.isUrlActive('/foo/bar'), isFalse);
        expect(router.isUrlActive('/foo/bar/baz'), isFalse);
        expect(router.isUrlActive('/foo/qux'), isTrue);

        await router.route('/foo/bar/baz');
        expect(r(router, 'foo').isActive, true);
        expect(r(router, 'foo.bar').isActive, true);
        expect(r(router, 'foo.bar.baz').isActive, true);
        expect(r(router, 'foo.qux').isActive, false);

        expect(router.isUrlActive('/foo'), isTrue);
        expect(router.isUrlActive('/foo/bar'), isTrue);
        expect(router.isUrlActive('/foo/bar/baz'), isTrue);
        expect(router.isUrlActive('/foo/qux'), isFalse);
      });
    });

    group('parameters', () {
      test('should return path parameters for routes', () async {
        router.root
          ..addRoute(
              name: 'foo',
              path: '/:foo',
              mount: (child) => child
                ..addRoute(
                    name: 'bar',
                    path: '/:bar',
                    mount: (child) => child
                      ..addRoute(
                          name: 'baz',
                          path: '/:baz',
                          mount: (child) => child)));

        expect(r(router, 'foo').parameters, isNull);
        expect(r(router, 'foo.bar').parameters, isNull);
        expect(r(router, 'foo.bar.baz').parameters, isNull);

        await router.route('/aaa');
        expect(r(router, 'foo').parameters, {'foo': 'aaa'});
        expect(r(router, 'foo.bar').parameters, isNull);
        expect(r(router, 'foo.bar.baz').parameters, isNull);

        await router.route('/aaa/bbb');
        expect(r(router, 'foo').parameters, {'foo': 'aaa'});
        expect(r(router, 'foo.bar').parameters, {'bar': 'bbb'});
        expect(r(router, 'foo.bar.baz').parameters, isNull);

        await router.route('/aaa/bbb/ccc');
        expect(r(router, 'foo').parameters, {'foo': 'aaa'});
        expect(r(router, 'foo.bar').parameters, {'bar': 'bbb'});
        expect(r(router, 'foo.bar.baz').parameters, {'baz': 'ccc'});
      });
    });
  });

  group('activePath', () {
    test('should correctly identify active path', () async {
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

      await router.route('/foo/qux');
      expect(strPath(router.activePath), 'foo.qux');

      await router.route('/foo/bar/baz');
      expect(strPath(router.activePath), 'foo.bar.baz');
    });
  });

  group('getRoutePathForUrl', () {
    setUp(() {
      router.root
        ..addRoute(name: 'RouteName1', path: '/routePath1')
        ..addRoute(
            name: 'RouteName2',
            path: '/routePath2',
            mount: (router) => router
              ..addRoute(
                  name: 'NestRouteName', path: '/nestRoute/:nestRouteParam'));
    });

    test('should return a base route path', () {
      List<Route> routePath = router.getRoutePathForUrl('/routePath1');
      expect(routePath.length, equals(1));

      Route baseRoute = routePath[0];
      expect(baseRoute.name, equals('RouteName1'));
      expect(baseRoute.parameters, equals({}));
      expect(baseRoute.queryParameters, equals({}));
    });

    test('should return a nested route path', () {
      List<Route> routePath =
          router.getRoutePathForUrl('/routePath2/nestRoute/param87');
      expect(routePath.length, equals(2));

      Route route = routePath[0];
      expect(route.name, equals('RouteName2'));
      expect(route.parameters, equals({}));
      expect(route.queryParameters, equals({}));

      route = routePath[1];
      expect(route.name, equals('NestRouteName'));
      expect(route.parameters, equals({'nestRouteParam': 'param87'}));
      expect(route.queryParameters, equals({}));
    });

    test('should return a route path with query params', () {
      List<Route> routePath =
          router.getRoutePathForUrl('/routePath2/nestRoute/param87?what=ever');
      expect(routePath.length, equals(2));

      Route route = routePath[0];
      expect(route.name, equals('RouteName2'));
      expect(route.parameters, equals({}));
      expect(route.queryParameters, equals({'what': 'ever'}));

      route = routePath[1];
      expect(route.name, equals('NestRouteName'));
      expect(route.parameters, equals({'nestRouteParam': 'param87'}));
      expect(route.queryParameters, equals({'what': 'ever'}));
    });
  });
}

/// An alias for Router.root.findRoute(path)
r(Router router, String path) => router.root.findRoute(path);
