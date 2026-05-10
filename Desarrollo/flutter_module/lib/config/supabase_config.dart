import 'package:flutter/services.dart';

/// Configuración de Supabase inicializada una sola vez al arranque desde Java.
/// Usada por ImageUploadService para construir las URLs de Storage.
class SupabaseConfig {
  static SupabaseConfig? _instance;
  static SupabaseConfig get instance {
    assert(_instance != null, 'SupabaseConfig no fue inicializado. Llamá initialize() en main().');
    return _instance!;
  }

  final String url;
  final String key;

  SupabaseConfig._({required this.url, required this.key});

  static Future<void> initialize() async {
    const channel = MethodChannel('com.example.bocado/access');
    final Map<dynamic, dynamic> config =
        await channel.invokeMethod('getSupabaseConfig');
    _instance = SupabaseConfig._(
      url: config['url'] as String,
      key: config['key'] as String,
    );
  }

  /// URL base para objetos públicos de Storage.
  String storagePublicUrl(String bucket, String path) =>
      '$url/storage/v1/object/public/$bucket/$path';

  /// URL del endpoint de upload para Storage.
  String storageUploadUrl(String bucket, String path) =>
      '$url/storage/v1/object/$bucket/$path';
}
