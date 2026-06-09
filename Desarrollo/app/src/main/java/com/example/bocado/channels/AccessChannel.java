package com.example.bocado.channels;

import android.app.Activity;
import com.example.bocado.BuildConfig;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.Managers.UsuarioManager;
import com.example.bocado.entidades.Usuario;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import org.json.JSONObject;
import java.util.HashMap;
import java.util.Map;

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
            case "loginJava"         -> handleLogin(call, result);
            case "register"          -> handleRegister(call, result);
            case "registerJava"      -> handleRegister(call, result);
            case "loginOrCreateGoogle" -> handleVerify(call,result);
            case "getNaciones"       -> handleGetNaciones(result);
            case "getGeneros"        -> handleGetGeneros(result);
            case "getSupabaseConfig" -> handleGetSupabaseConfig(result);
            case "actualizarPerfil"  -> handleActualizarPerfil(call, result);
            case "getPerfilUsuario" -> handleGetPerfilUsuario(call, result);
            case "validarSesion"    -> handleValidarSesion(call, result);
            default -> result.notImplemented();
        }
    }

    private void handleVerify(MethodCall call, MethodChannel.Result result){
        String googleId = call.argument("googleId");
        String email    = call.argument("email");
        String nombre   = call.argument("nombre");
        String apellido = call.argument("apellido");
        String foto     = call.argument("foto");

        usuarioManager.loginOrCreateGoogle(email, googleId, nombre, apellido, foto, new CallbackCB() {
            @Override
            public void onSuccess(String response) {
                activity.runOnUiThread(() -> result.success(response));
            }
            @Override
            public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        });
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
        u.setFechaNacimientoIso(call.argument("fechaNacimiento"));

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

    private void handleGetSupabaseConfig(MethodChannel.Result result) {
        // La anon key es pública por diseño — seguro exponerla al cliente Flutter
        String rawUrl = BuildConfig.SUPABASE_URL;
        // Eliminar trailing slash si lo tiene para construir URLs de Storage correctamente
        String url = rawUrl.endsWith("/") ? rawUrl.substring(0, rawUrl.length() - 1) : rawUrl;

        Map<String, String> config = new HashMap<>();
        config.put("url", url);
        config.put("key", BuildConfig.SUPABASE_KEY);
        result.success(config);
    }

    private void handleActualizarPerfil(MethodCall call, MethodChannel.Result result) {
        try {
            int id = call.argument("id");
            JSONObject actualizaciones = new JSONObject();

            String usuario = call.argument("usuario");
            if (usuario != null && !usuario.trim().isEmpty())
                actualizaciones.put("usuario", usuario.trim());

            String correo = call.argument("correo");
            if (correo != null && !correo.trim().isEmpty())
                actualizaciones.put("correo", correo.trim());

            String genero = call.argument("genero");
            if (genero != null && !genero.trim().isEmpty())
                actualizaciones.put("genero", genero.trim());

            String fotoUrl = call.argument("fotoUrl");
            if (fotoUrl != null && !fotoUrl.trim().isEmpty())
                actualizaciones.put("foto_url", fotoUrl.trim());

            String bannerUrl = call.argument("bannerUrl");
            if (bannerUrl != null && !bannerUrl.trim().isEmpty())
                actualizaciones.put("banner_url", bannerUrl.trim());

            usuarioManager.actualizar(id, actualizaciones, new CallbackCB() {
                @Override public void onSuccess(String response) {
                    activity.runOnUiThread(() -> result.success("ok"));
                }
                @Override public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            });
        } catch (Exception e) {
            result.error("ERROR_INTERNO", e.getMessage(), null);
        }
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

    /** Revalida que la cuenta exista y siga activa (para auto-login al arrancar). */
    private void handleValidarSesion(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        HttpClientManager.getInstance().get("/rest/v1/usuarios?id=eq." + idUsuario + "&activo=eq.true&select=id", new okhttp3.Callback() {
            @Override public void onFailure(okhttp3.Call call, java.io.IOException e) {
                activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
            }
            @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                String body = response.body() != null ? response.body().string() : "[]";
                activity.runOnUiThread(() -> result.success(body));
            }
        });
    }

    private void handleGetPerfilUsuario(MethodCall call, MethodChannel.Result result){
        Integer idUsuario = call.argument("id_usuario");
        HttpClientManager.getInstance().get("/rest/v1/usuarios?id=eq." + idUsuario + "&select=*", new okhttp3.Callback() {
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
