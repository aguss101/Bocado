package com.example.bocado;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.bocado/login";
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {

        super.configureFlutterEngine(flutterEngine);
        // MethodChannels van acá
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if(call.method.equals("loginJava")){
                                //codigo
                                String respuesta = "aprobado. ";
                                result.success(respuesta);
                            } else {
                                result.notImplemented();
                            }
        }
        );
    }
}