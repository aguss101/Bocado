package com.example.bocado;

import com.example.bocado.DAO.LoginCallback;
import com.example.bocado.DAO.UsuarioDAO2;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;

import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.entidades.Usuario;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.example.bocado/login";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.bocado/login")
                .setMethodCallHandler((call, result) -> {

                    if (call.method.equals("loginJava")) {

                        String usuario = call.argument("usuario");
                        String contrasena = call.argument("contrasena");

                        UsuarioDAO2.login(usuario, contrasena, new LoginCallback() {
                            @Override
                            public void onSuccess(String response) {
                                runOnUiThread(() -> result.success(response));
                            }

                            @Override
                            public void onError(String code, String message, Object details) {
                                runOnUiThread(() -> result.error(code, message, details));
                            }
                        });
                    }
                });
    }
}