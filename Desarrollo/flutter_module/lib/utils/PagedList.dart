class PagedList<T> {
  final Future<List<T>> Function(int offset, int limit) fetch;
  final int pageSize;
  final List<T> items = [];
  int _offset = 0;
  bool cargando = true;
  bool cargandoMas = false;
  bool hayMas = true;

  PagedList(this.fetch, {this.pageSize = 12});

  Future<void> cargarPrimera() async {
    cargando = true;
    try {
      final lista = await fetch(0, pageSize);
      items.clear();
      items.addAll(lista);
      _offset = lista.length;
      hayMas = lista.length == pageSize;
    } finally {
      cargando = false;
    }
  }

  Future<void> cargarMas() async {
    if (cargandoMas || !hayMas || cargando) return;
    cargandoMas = true;
    try {
      final lista = await fetch(_offset, pageSize);
      items.addAll(lista);
      _offset += lista.length;
      hayMas = lista.length == pageSize;
    } finally {
      cargandoMas = false;
    }
  }
}
