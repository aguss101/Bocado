import 'package:flutter/widgets.dart';

/// Observer global para detectar cuándo una pantalla vuelve a estar visible
/// (didPopNext) y poder refrescar datos como los contadores de perfil.
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
