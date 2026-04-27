package com.example.bocado.channels;

import android.app.Activity;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.Managers.UsuarioManager;
import com.example.bocado.entidades.Usuario;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;

public class AccessChannel {

    private static final String CHANNEL = "com.example.bocado/access";
    private final Activity activity;
    private final UsuarioManager usuarioManager;

    public AccessChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        this.usuarioManager = new UsuarioManager(new UsuarioDAO());

        new MethodChannel(messenger, CHANNEL)
                .setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "loginJava" -> handleLogin(call, result);
            case "register"  -> handleRegister(call, result);
            case "registerJava"  -> handleRegister(call, result);
            case "getNaciones" -> handleGetNaciones(result);
            case "getGeneros"  -> handleGetGeneros(result);
            default -> result.notImplemented();
        }
    }

    private void handleLogin(MethodCall call, MethodChannel.Result result) {
        String usuario   = call.argument("usuario");
        String contrasena = call.argument("contrasena");

        usuarioManager.login(usuario, contrasena, new CallbackCB() {
            @Override public void onSuccess(String response) {
                activity.runOnUiThread(() -> result.success(response));
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        });
    }

    private void handleRegister(MethodCall call, MethodChannel.Result result) {
        Usuario u = new Usuario();
        u.setNombre(call.argument("nombre"));
        u.setApellido(call.argument("apellido"));
        u.setCorreo(call.argument("email"));
        u.setUsuario(call.argument("usuario"));
        u.setContrasena(call.argument("password"));
        u.setNacion(String.valueOf(call.argument("nacion")));
        u.setGenero(String.valueOf(call.argument("genero")));
        u.setFecha_Nacimiento(call.argument("fechaNacimiento"));

        usuarioManager.registrar(u, new CallbackCB() {
            @Override public void onSuccess(String data) {
                activity.runOnUiThread(() -> result.success(data));
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        });
    }

    private void handleGetNaciones(MethodChannel.Result result) {
        HttpClientManager.getInstance().get("/rest/v1/naciones?select=*", new okhttp3.Callback() {
            @Override public void onFailure(okhttp3.Call call, java.io.IOException e) {
                activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
            }
            @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                String body = response.body() != null ? response.body().string() : "[]";
                activity.runOnUiThread(() -> result.success(body));
            }
        });
    }

    private void handleGetGeneros(MethodChannel.Result result) {
        HttpClientManager.getInstance().get("/rest/v1/generos?select=*", new okhttp3.Callback() {
            @Override public void onFailure(okhttp3.Call call, java.io.IOException e) {
                activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
            }
            @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                String body = response.body() != null ? response.body().string() : "[]";
                activity.runOnUiThread(() -> result.success(body));
            }
        });
    }
}
