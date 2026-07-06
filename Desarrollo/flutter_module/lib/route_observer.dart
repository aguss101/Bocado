import 'package:flutter/material.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class BocadoRouteTracker extends NavigatorObserver {
  final List<String> _stack = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null) _stack.add(name);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null) _stack.remove(name);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null) _stack.remove(name);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    final oldName = oldRoute?.settings.name;
    if (oldName != null) _stack.remove(oldName);
    final newName = newRoute?.settings.name;
    if (newName != null) _stack.add(newName);
  }

  bool contains(String name) => _stack.contains(name);
}

final BocadoRouteTracker bocadoRouteTracker = BocadoRouteTracker();

void pushOrReuse(BuildContext context, String routeName, WidgetBuilder builder) {
  if (bocadoRouteTracker.contains(routeName)) {
    Navigator.of(context).popUntil((r) => r.settings.name == routeName);
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(settings: RouteSettings(name: routeName), builder: builder),
    );
  }
}
