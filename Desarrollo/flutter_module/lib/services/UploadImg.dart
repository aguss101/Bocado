import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
  static const _channel = MethodChannel('com.example.bocado/images');

  static Future<XFile?> pickImage(ImageSource source) =>
      _picker.pickImage(source: source, imageQuality: 100);

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

  static Future<String> _upload(String bucket, String path, Uint8List bytes) async {
    final String url = await _channel.invokeMethod('subirImagen', {
      'bucket': bucket,
      'path': path,
      'bytes': bytes,
    });
    return url;
  }

  static Future<String?> _pickCompressUpload(
      ImageSource source, _Preset preset, String bucket, String path) async {
    final file = await pickImage(source);
    if (file == null) return null;
    final bytes = await _compress(file.path, preset);
    return _upload(bucket, path, bytes);
  }

  static Future<String?> uploadFotoPerfil(int userId, ImageSource source) =>
      _pickCompressUpload(source, _presetFoto, 'avatars', '$userId/foto.jpg');

  static Future<String?> uploadBanner(int userId, ImageSource source) =>
      _pickCompressUpload(source, _presetBanner, 'avatars', '$userId/banner.jpg');

  static Future<String?> uploadRecetaImage(String id, Uint8List source) =>
      _upload('recetas', '$id/portada.jpg', source);

  static Future<Uint8List?> pickAndCompressReceta(ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;
    return _compress(file.path, _presetReceta);
  }

  static Future<String> uploadRecetaBytes(int recetaId, Uint8List bytes) =>
      _upload('recetas', '$recetaId/portada.jpg', bytes);
}
