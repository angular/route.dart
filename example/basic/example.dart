library example;

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:route_hierarchical/client.dart';
import 'package:route_hierarchical/history_provider.dart';

main() {
  new Logger('')
    ..level = Level.FINEST
    ..onRecord.listen((r) => print('[${r.level}] ${r.message}'));

  querySelector('#warning').remove();

  // set up the default router to control 1 section of the example page
  var router = new Router(useFragment: true);

  router.root
    ..addRoute(
        name: 'one',
        defaultRoute: true,
        path: '/one',
        pageTitle: 'Route One',
        enter: showR1One)
    ..addRoute(
        name: 'two', path: '/two', pageTitle: 'Route Two', enter: showR1Two);

  querySelector('#R1linkOne').attributes['href'] = router.url('one');
  querySelector('#R1linkTwo').attributes['href'] = router.url('two');

  router.listen();

  // set up a second router that doesn't affect the url for a different section of the page
  var router2 =
      new Router(useFragment: true, historyProvider: new MemoryHistory());

  router2.root
    ..addRoute(
        name: 'one', path: '/one', pageTitle: 'Route One', enter: showR2One)
    ..addRoute(
        name: 'two',
        defaultRoute: true,
        path: '/two',
        pageTitle: 'Route Two',
        enter: showR2Two);

  querySelector('#R2linkOne').attributes['href'] = router2.url('one');
  querySelector('#R2linkTwo').attributes['href'] = router2.url('two');

  router2.listen();
}

void showR1One(RouteEvent e) {
  print("showR1One");
  querySelector('#R1one').classes.add('selected');
  querySelector('#R1two').classes.remove('selected');
}

void showR1Two(RouteEvent e) {
  print("showR1Two");
  querySelector('#R1one').classes.remove('selected');
  querySelector('#R1two').classes.add('selected');
}

void showR2One(RouteEvent e) {
  print("showR2One");
  querySelector('#R2one').classes.add('selected');
  querySelector('#R2two').classes.remove('selected');
}

void showR2Two(RouteEvent e) {
  print("showR2Two");
  querySelector('#R2one').classes.remove('selected');
  querySelector('#R2two').classes.add('selected');
}
