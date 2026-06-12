package com.example.bocado.channels;

import android.app.Activity;
import com.example.bocado.BuildConfig;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.Managers.UsuarioManager;
import com.example.bocado.Estaticos.RpcCallHelper;
import com.example.bocado.Estaticos.Mapper;
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
            case "registerJava"      -> handleRegister(call, result);
            case "loginGoogle"       -> handleLoginGoogle(call, result);
            case "registrarGoogle"   -> handleRegistrarGoogle(call, result);
            case "getNaciones"       -> handleGetNaciones(result);
            case "getGeneros"        -> handleGetGeneros(result);
            case "getSupabaseConfig" -> handleGetSupabaseConfig(result);
            case "actualizarPerfil"  -> handleActualizarPerfil(call, result);
            case "getPerfilUsuario" -> handleGetPerfilUsuario(call, result);
            case "validarSesion"    -> handleValidarSesion(call, result);
            default -> result.notImplemented();
        }
    }

    /** Paso 1 del login social: ¿ya existe una cuenta con ese correo? */
    private void handleLoginGoogle(MethodCall call, MethodChannel.Result result) {
        String email = call.argument("email");
        if (email == null || email.trim().isEmpty()) {
            result.error("NEGOCIO", "Google no devolvió un correo.", null);
            return;
        }

        String correoQuery;
        try {
            correoQuery = java.net.URLEncoder.encode(email, "UTF-8");
        } catch (java.io.UnsupportedEncodingException e) {
            correoQuery = email;
        }

        HttpClientManager.getInstance().get(
                "/rest/v1/usuarios?correo=eq." + correoQuery + "&activo=eq.true&select=id,id_cuenta,usuario,foto,banner",
                new okhttp3.Callback() {
                    @Override public void onFailure(okhttp3.Call call, java.io.IOException e) {
                        activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                    }
                    @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                        String body = response.body() != null ? response.body().string() : "[]";
                        activity.runOnUiThread(() -> result.success(body));
                    }
                });
    }

    // Crear usuario con Google
    private void handleRegistrarGoogle(MethodCall call, MethodChannel.Result result) {
        try {
            JSONObject data = new JSONObject();
            data.put("correo", (String) call.argument("correo"));
            data.put("nombre", (String) call.argument("nombre"));
            data.put("apellido", (String) call.argument("apellido"));
            String foto = call.argument("foto");
            data.put("foto", foto != null ? foto : "");
            data.put("id_nacion", (Integer) call.argument("nacion"));
            data.put("id_genero", (Integer) call.argument("genero"));
            data.put("fecha_nacimiento", (String) call.argument("fechaNacimiento"));

            JSONObject json = new JSONObject();
            json.put("p_data", data);

            RpcCallHelper.callAsync("registrar_usuario_google", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    JSONObject obj = RpcCallHelper.firstOrNull(response);
                    if (obj != null) {
                        activity.runOnUiThread(() -> result.success(obj.toString()));
                    } else {
                        activity.runOnUiThread(() -> result.error("ERROR_REGISTRO", "No se pudo crear el usuario de Google.", null));
                    }
                }
                @Override
                public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            });
        } catch (Exception e) {
            result.error("ERROR_JSON", "Error armando datos de Google: " + e.getMessage(), null);
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
        // valor Int primero para forzar String.valueOf(Object):
        Integer idNacion = call.argument("nacion");
        Integer idGenero = call.argument("genero");
        u.setNacion(String.valueOf((Object) idNacion));
        u.setGenero(String.valueOf((Object) idGenero));
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

    private void handleGetSupabaseConfig(MethodChannel.Result result) {
        String rawUrl = BuildConfig.SUPABASE_URL;
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
                actualizaciones.put("foto", fotoUrl.trim());

            String bannerUrl = call.argument("bannerUrl");
            if (bannerUrl != null && !bannerUrl.trim().isEmpty())
                actualizaciones.put("banner", bannerUrl.trim());

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

    // Revalida que la cuenta exista y siga activa (para auto-login al arrancar)
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
                try {
                    org.json.JSONArray filas = new org.json.JSONArray(body);
                    if (filas.length() == 0) {
                        activity.runOnUiThread(() -> result.error("NOT_FOUND", "Usuario no encontrado", null));
                        return;
                    }
                    // El mapeo vive en Java (Mapper), no en Flutter. Devolvemos un
                    // objeto limpio y sin contraseña en vez del body crudo de Supabase.
                    Usuario u = Mapper.jsonToUsuario(filas.getJSONObject(0));
                    String perfil = Mapper.usuarioToClientJson(u).toString();
                    activity.runOnUiThread(() -> result.success(perfil));
                } catch (org.json.JSONException e) {
                    activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                }
            }
        });
    }
}
