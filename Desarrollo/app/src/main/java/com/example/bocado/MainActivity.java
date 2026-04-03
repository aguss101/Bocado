package com.example.bocado;

import com.example.bocado.DAO.LoginCallback;
import com.example.bocado.DAO.UsuarioDAO;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.example.bocado/access";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.example.bocado/access")
                .setMethodCallHandler((call, result) -> {

                    switch (call.method){
                        case "loginJava":
                            String usuario = call.argument("usuario");
                            String contrasena = call.argument("contrasena");

                            UsuarioDAO.login(usuario, contrasena, new LoginCallback() {
                                @Override
                                public void onSuccess(String response) {
                                    runOnUiThread(() -> result.success(response));
                                }
                                @Override
                                public void onError(String code, String message, Object details) {
                                    runOnUiThread(() -> result.error(code, message, details));
                                }
                            });
                            break;

                        case "registerJava":
                            Integer idNacion = call.argument("nacion");
                            Integer idGenero = call.argument("genero");
                            String nombre = call.argument("nombre");
                            String apellido = call.argument("apellido");
                            String email = call.argument("email");
                            String user = call.argument("usuario");
                            String password = call.argument("password");
                            String fechaNacimiento = call.argument("fechaNacimiento");

                            UsuarioDAO.register(idNacion, idGenero, nombre, apellido, email, user, password, fechaNacimiento, new LoginCallback() {
                                @Override
                                public void onSuccess(String responseData) { runOnUiThread(() -> result.success(responseData)); }
                                @Override
                                public void onError(String code, String message, Object details) { runOnUiThread(() -> result.error(code, message, details)); }
                            });
                            break;

                        case "getNaciones":
                            UsuarioDAO.trearTabla("naciones", new LoginCallback() {
                                @Override
                                public void onSuccess(String responseData) {runOnUiThread(() -> result.success(responseData));}
                                @Override
                                public void onError(String code, String message, Object details) {runOnUiThread(() -> result.error(code, message, details));}
                            });
                            break;

                        case "getGeneros":
                            UsuarioDAO.trearTabla("generos", new LoginCallback() {
                                @Override
                                public void onSuccess(String responseData) {runOnUiThread(() -> result.success(responseData));}
                                @Override
                                public void onError(String code, String message, Object details) {runOnUiThread(() -> result.error(code, message, details));}
                            });
                            break;

                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }
}