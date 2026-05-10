import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

/// Límites de compresión por tipo de imagen.
/// El celular puede sacar fotos de 10+ MB — acá las reducimos antes de subir.
class _Preset {
  final int width;
  final int height;
  final int quality;
  const _Preset(this.width, this.height, this.quality);
}

const _presetFoto   = _Preset(400,  400,  80);
const _presetBanner = _Preset(1200, 400,  80);
const _presetReceta = _Preset(1200, 900,  85);

class ImageUploadService {
  static final _picker = ImagePicker();

  // ── PICK ──────────────────────────────────────────────────────────────────

  /// Abre galería o cámara. Devuelve null si el usuario canceló.
  static Future<XFile?> pickImage(ImageSource source) =>
      _picker.pickImage(source: source, imageQuality: 100);

  // ── COMPRESS ──────────────────────────────────────────────────────────────

  static Future<Uint8List> _compress(String path, _Preset p) async {
    final result = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: p.width,
      minHeight: p.height,
      quality: p.quality,
      format: CompressFormat.jpeg,
    );
    if (result == null) throw Exception('No se pudo comprimir la imagen.');
    return result;
  }

  // ── UPLOAD ────────────────────────────────────────────────────────────────

  static Future<String> _upload(String bucket, String path, Uint8List bytes) async {
    final cfg = SupabaseConfig.instance;
    final uri = Uri.parse(cfg.storageUploadUrl(bucket, path));

    final response = await http.post(
      uri,
      headers: {
        'apikey':         cfg.key,
        'Authorization':  'Bearer ${cfg.key}',
        'Content-Type':   'image/jpeg',
        'x-upsert':       'true',   // sobreescribe si ya existe
      },
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al subir imagen (${response.statusCode}): ${response.body}');
    }

    return cfg.storagePublicUrl(bucket, path);
  }

  // ── API PÚBLICA ───────────────────────────────────────────────────────────

  /// Elige y sube la foto de perfil. Devuelve la URL pública o null si canceló.
  static Future<String?> uploadFotoPerfil(int userId, ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;
    final bytes = await _compress(file.path, _presetFoto);
    return _upload('avatars', '$userId/foto.jpg', bytes);
  }

  /// Elige y sube el banner de perfil. Devuelve la URL pública o null si canceló.
  static Future<String?> uploadBanner(int userId, ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;
    final bytes = await _compress(file.path, _presetBanner);
    return _upload('avatars', '$userId/banner.jpg', bytes);
  }

  /// Elige y sube la imagen de una receta. Devuelve la URL pública o null si canceló.
  static Future<String?> uploadRecetaImage(int recetaId, ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;
    final bytes = await _compress(file.path, _presetReceta);
    return _upload('recetas', '$recetaId/portada.jpg', bytes);
  }

  /// Solo elige y comprime (sin subir). Útil cuando el ID aún no existe.
  static Future<Uint8List?> pickAndCompressReceta(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;
    return _compress(file.path, _presetReceta);
  }

  /// Sube bytes ya comprimidos para una receta (usar tras obtener el ID real).
  static Future<String> uploadRecetaBytes(int recetaId, Uint8List bytes) =>
      _upload('recetas', '$recetaId/portada.jpg', bytes);
}
