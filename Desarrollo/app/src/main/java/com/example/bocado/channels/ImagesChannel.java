package com.example.bocado.channels;

import android.app.Activity;
import com.example.bocado.Managers.HttpClientManager;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;

/**
 * Canal de subida de imágenes a Supabase Storage. Flutter elige y comprime la
 * imagen (frontend) y manda los bytes por acá; la subida (backend) vive en Java.
 */
public class ImagesChannel {

    private static final String CHANNEL = "com.example.bocado/images";
    private final Activity activity;

    public ImagesChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        new MethodChannel(messenger, CHANNEL).setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        if ("subirImagen".equals(call.method)) {
            handleSubirImagen(call, result);
        } else {
            result.notImplemented();
        }
    }

    /** Sube los bytes recibidos a {bucket}/{path} y devuelve la URL pública. */
    private void handleSubirImagen(MethodCall call, MethodChannel.Result result) {
        String bucket = call.argument("bucket");
        String path   = call.argument("path");
        byte[] bytes  = call.argument("bytes");

        if (bucket == null || path == null || bytes == null) {
            result.error("ARGS", "Faltan bucket/path/bytes para subir la imagen.", null);
            return;
        }

        HttpClientManager.getInstance().uploadImage(bucket, path, bytes, new okhttp3.Callback() {
            @Override public void onFailure(okhttp3.Call call, java.io.IOException e) {
                activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
            }
            @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                if (!response.isSuccessful()) {
                    int code = response.code();
                    String body = response.body() != null ? response.body().string() : "";
                    activity.runOnUiThread(() -> result.error("UPLOAD_ERROR", "Storage respondió " + code + ": " + body, null));
                    return;
                }
                String url = HttpClientManager.getInstance().storagePublicUrl(bucket, path);
                activity.runOnUiThread(() -> result.success(url));
            }
        });
    }
}
