part of route.client;

/**
 * A helper RouteView object that supplies a read-only view of route
 * information.  This is intended as a source of route information for a
 * particular route in a particular state and, unlike Route, does NOT imply
 * that this route configuration is currently active.
 *
 * A RouteView should be used as a source of information ONLY and
 * should not be used for any other routing operations.
 */
class RouteView implements Route {
  Route _route;
  Map _parameters;
  Map _queryParameters;

  RouteView(Route route, {Map parameters, Map queryParameters}) {
    _route = route;
    _parameters = parameters ?? {};
    _queryParameters = queryParameters ?? {};
  }

  /// See [Route.name]
  @override
  String get name => _route.name;

  /// See [Route.path]
  @override
  UrlMatcher get path => _route.path;

  /// See [Route.parent]
  @override
  Route get parent => _route.parent;

  /// See [Route.isActive]
  @override
  bool get isActive => _route.isActive;

  /**
   * Returns parameters for the specified RouteView.  Non-empty parameters
   * does NOT imply that the specified route is currently active.
   */
  @override
  Map get parameters => _parameters;

  /**
   * Returns query parameters for the specified RouteView.  Non-empty query
   * parameters does NOT imply that the specified route is currently active.
   */
  @override
  Map get queryParameters => _queryParameters;

  /// See [Route.dontLeaveOnParamChanges]
  @override
  bool get dontLeaveOnParamChanges => _route.dontLeaveOnParamChanges;

  /// See [Route.pageTitle]
  @override
  String get pageTitle => _route.pageTitle;

  /// See [Route.onPreEnter]
  @override
  Stream<RoutePreEnterEvent> get onPreEnter => _route.onPreEnter;

  /// See [Route.onPreLeave]
  @override
  Stream<RoutePreLeaveEvent> get onPreLeave => _route.onPreLeave;

  /// See [Route.onLeave]
  @override
  Stream<RouteLeaveEvent> get onLeave => _route.onLeave;

  /// See [Route.onEnter]
  @override
  Stream<RouteEnterEvent> get onEnter => _route.onEnter;

  /// Not supported. Overridden to throw an error.
  @override
  void addRoute(
      {String name,
      Pattern path,
      bool defaultRoute: false,
      RouteEnterEventHandler enter,
      RoutePreEnterEventHandler preEnter,
      RoutePreLeaveEventHandler preLeave,
      RouteLeaveEventHandler leave,
      mount,
      dontLeaveOnParamChanges: false,
      String pageTitle,
      List<Pattern> watchQueryParameters}) {
    throw new UnsupportedError('addRoute is not supported by RouteView');
  }

  /// Not supported. Overridden to throw an error.
  @override
  Route findRoute(String routePath) {
    throw new UnsupportedError('findRoute is not supported by RouteView');
  }

  /// Not supported. Overridden to throw an error.
  @override
  Route newHandle() {
    throw new UnsupportedError('newHandle is not supported by RouteView');
  }

  /// See [Route.toString]
  @override
  String toString() => _route.toString();
}
