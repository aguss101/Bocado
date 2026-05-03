import 'dart:typed_data';

class usuario_Logged{
  int id;
  int id_Cuenta;
  String usuario;
  String? fotoRaw;
  Uint8List? fotoReady;
  String? bannerRaw;
  Uint8List? bannerReady;

  usuario_Logged(
      this.id,
      this.id_Cuenta,
      this.usuario,
      this.fotoRaw,
      this.bannerRaw
      ){
    fotoReady = _parseSupabaseBytea(fotoRaw);
    bannerReady = _parseSupabaseBytea(bannerRaw);
  }
  Uint8List? _parseSupabaseBytea(String? pic){
    if (pic==null || pic.isEmpty) return null;

    String hex = pic;

    if(hex.startsWith(r'\x')){
      hex = hex.substring(2);
    }
    List<int> bytes = [];
    for(int i=0; i<hex.length; i+=2){
      bytes.add((int.parse(hex.substring(i,i + 2), radix: 16)));
    }

    return Uint8List.fromList(bytes);
  }
}