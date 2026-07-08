package com.example.bocado.Channels;

import android.app.Activity;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.Managers.UsuarioManager;
import com.example.bocado.Estaticos.RpcCallHelper;
import com.example.bocado.Estaticos.Mapper;
import com.example.bocado.Entidades.Usuario;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import org.json.JSONObject;

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
            case "registrarGoogle"   -> handleRegisterGoogle(call, result);
            case "getNaciones"       -> handleGetNaciones(result);
            case "getGeneros"        -> handleGetGeneros(result);
            case "getSeguidores" -> handleGetSeguidores(call, result);
            case "getSeguidoresDe" -> handleGetSeguidoresDe(call, result);
            case "actualizarPerfil"  -> handleActualizarPerfil(call, result);
            case "getPerfilUsuario" -> handleGetPerfilUsuario(call, result);
            case "getPerfilEditable" -> handleGetPerfilEditable(call, result);
            case "contarSeguidores" -> handleContarSeguidores(call, result);
            case "contarSiguiendo"  -> handleContarSiguiendo(call, result);
            case "estasSiguiendo"   -> handleEstasSiguiendo(call, result);
            case "estasSiguiendoVarios" -> handleEstasSiguiendoVarios(call, result);
            case "validarSesion"    -> handleValidarSesion(call, result);
            case "solicitarOtp"     -> handleSolicitarOtp(call, result);
            case "verificarOtp"     -> handleVerificarOtp(call, result);
            case "resetearPassword" -> handleResetPass(call, result);
            case "actualizarPerfilOtp" -> handleActualizarPerfilOtp(call, result);
            case "solicitarVerificacionCorreo" -> handleSolicitarVerificacionCorreo(call, result);
            case "verificarCodigoRegistro" -> handleVerificarCodigoRegistro(call, result);
            case "verificarLinkRegistro" -> handleVerificarLinkRegistro(call, result);
            case "buscarUsuario" -> handleBuscarUsuario(call, result);
            default -> result.notImplemented();
        }
    }

    private void handleLoginGoogle(MethodCall call, MethodChannel.Result result) {
        String email = call.argument("email");
        if (email == null || email.trim().isEmpty()) {
            result.error("NEGOCIO", "Google no devolvió un correo.", null);
            return;
        }

        JSONObject body = new JSONObject();
        try {
            body.put("p_correo", email);
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
            return;
        }
        RpcCallHelper.callAsync("buscar_usuario_por_correo_google", body, new CallbackCB() {
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

    private void handleRegisterGoogle(MethodCall call, MethodChannel.Result result) {
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
                        responderUsuarioLimpio(obj.toString(), result);
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
                responderUsuarioLimpio(response, result);
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
        Integer idNacion = call.argument("nacion");
        Integer idGenero = call.argument("genero");
        u.setNacion(String.valueOf((Object) idNacion));
        u.setGenero(String.valueOf((Object) idGenero));
        u.setFecha_Nacimiento(call.argument("fechaNacimiento"));

        usuarioManager.register(u, new CallbackCB() {
            @Override public void onSuccess(String data) {
                responderUsuarioLimpio(data, result);
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        });
    }

    private void handleGetNaciones(MethodChannel.Result result) {
        HttpClientManager.getInstance().get("/rest/v1/naciones?select=*",
                HttpClientManager.simpleCallback(bridgeData(result), false));
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

            Integer idGenero = call.argument("id_genero");
            if (idGenero != null)
                actualizaciones.put("id_genero", idGenero);

            String fotoUrl = call.argument("fotoUrl");
            if (fotoUrl != null && !fotoUrl.trim().isEmpty())
                actualizaciones.put("foto", fotoUrl.trim());

            String bannerUrl = call.argument("bannerUrl");
            if (bannerUrl != null && !bannerUrl.trim().isEmpty())
                actualizaciones.put("banner", bannerUrl.trim());

            Boolean visibilidad = call.argument("visibilidad");
            if (visibilidad != null)
                actualizaciones.put("visibilidad", visibilidad);

            String bio = call.argument("bio");
            if (bio != null && !bio.trim().isEmpty())
                actualizaciones.put("bio", bio);

            usuarioManager.update(id, actualizaciones, new CallbackCB() {
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
        HttpClientManager.getInstance().get("/rest/v1/generos?select=*",
                HttpClientManager.simpleCallback(bridgeData(result), false));
    }

    private void handleGetSeguidores(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        Integer limit = call.argument("limit");
        Integer offset = call.argument("offset");
        String url = "/rest/v1/vista_mis_seguidos?select=*&id_seguidor=eq." + idUsuario
                + HttpClientManager.paginar("id_seguido", limit, offset);
        HttpClientManager.getInstance().get(url,
                HttpClientManager.simpleCallback(bridgeData(result), false));
    }

    private void handleEstasSiguiendoVarios(MethodCall call, MethodChannel.Result result) {
        Integer idSeguidor = call.argument("id_seguidor");
        java.util.List<Integer> ids = call.argument("ids_seguido");
        if (ids == null || ids.isEmpty()) {
            result.success("[]");
            return;
        }
        StringBuilder lista = new StringBuilder();
        for (int i = 0; i < ids.size(); i++) {
            if (i > 0) lista.append(",");
            lista.append(ids.get(i));
        }
        String url = "/rest/v1/seguidos_usuario?select=id_seguido&id_seguidor=eq." + idSeguidor
                + "&id_seguido=in.(" + lista + ")";
        HttpClientManager.getInstance().get(url, HttpClientManager.simpleCallback(new CallbackCB() {
            @Override public void onSuccess(String body) {
                try {
                    org.json.JSONArray filas = new org.json.JSONArray(body);
                    org.json.JSONArray idsSeguidos = new org.json.JSONArray();
                    for (int i = 0; i < filas.length(); i++) {
                        idsSeguidos.put(filas.getJSONObject(i).optInt("id_seguido"));
                    }
                    String bodyPlano = idsSeguidos.toString();
                    activity.runOnUiThread(() -> result.success(bodyPlano));
                } catch (org.json.JSONException e) {
                    activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                }
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        }, false));
    }

    private void handleGetSeguidoresDe(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        Integer limit = call.argument("limit");
        Integer offset = call.argument("offset");
        String url = "/rest/v1/seguidos_usuario?" +
                "select=id_seguidor,usuarios!id_seguidor(id,usuario,foto)&id_seguido=eq." + idUsuario
                + HttpClientManager.paginar("fecha_seguido", limit, offset);
        HttpClientManager.getInstance().get(url, HttpClientManager.simpleCallback(new CallbackCB() {
            @Override public void onSuccess(String body) {
                try {
                    org.json.JSONArray filas = new org.json.JSONArray(body);
                    org.json.JSONArray reacomodadas = new org.json.JSONArray();
                    for (int i = 0; i < filas.length(); i++) {
                        JSONObject fila = filas.getJSONObject(i);
                        JSONObject usuario = fila.optJSONObject("usuarios");
                        if (usuario == null) continue;
                        JSONObject plana = new JSONObject();
                        plana.put("id_seguido", idUsuario);
                        plana.put("id_seguidor", fila.optInt("id_seguidor"));
                        plana.put("nombre_usuario", usuario.optString("usuario", "Usuario"));
                        plana.put("foto_url", usuario.isNull("foto") ? JSONObject.NULL : usuario.optString("foto"));
                        plana.put("total_recetas", 0);
                        reacomodadas.put(plana);
                    }
                    String bodyReacomodado = reacomodadas.toString();
                    activity.runOnUiThread(() -> result.success(bodyReacomodado));
                } catch (org.json.JSONException e) {
                    activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                }
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        }, false));
    }

    private void handleValidarSesion(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        HttpClientManager.getInstance().get("/rest/v1/usuarios?id=eq." + idUsuario + "&activo=eq.true&select=id",
                HttpClientManager.simpleCallback(bridgeData(result), false));
    }

    private void handleGetPerfilUsuario(MethodCall call, MethodChannel.Result result){
        Integer idUsuario = call.argument("id_usuario");
        String cols = "id,id_cuenta,id_nacion,id_genero,nombre,apellido,usuario,"
                + "fecha_nacimiento,fecha_creacion,fecha_acceso,activo,visibilidad,foto,banner,bio";
        HttpClientManager.getInstance().get("/rest/v1/usuarios?id=eq." + idUsuario + "&select=" + cols,
                HttpClientManager.simpleCallback(new CallbackCB() {
            @Override public void onSuccess(String body) {
                JSONObject fila = RpcCallHelper.firstOrNull(body);
                if (fila == null) {
                    activity.runOnUiThread(() -> result.error("NOT_FOUND", "Usuario no encontrado", null));
                    return;
                }
                responderUsuarioLimpio(fila.toString(), result);
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        }, false));
    }

    private void handleContarSeguidores(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        HttpClientManager.getInstance().get("/rest/v1/estadisticas_usuario?select=cant_seguidores&id_usuario=eq." + idUsuario,
                HttpClientManager.simpleCallback(new CallbackCB() {
            @Override public void onSuccess(String body) {
                try {
                    org.json.JSONArray filas = new org.json.JSONArray(body);
                    int total = filas.length() > 0 ? filas.getJSONObject(0).optInt("cant_seguidores", 0) : 0;
                    activity.runOnUiThread(() -> result.success(total));
                } catch (org.json.JSONException e) {
                    activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                }
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        }, false));
    }

    private void handleContarSiguiendo(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        HttpClientManager.getInstance().get("/rest/v1/estadisticas_usuario?select=cant_siguiendo&id_usuario=eq." + idUsuario,
                HttpClientManager.simpleCallback(new CallbackCB() {
            @Override public void onSuccess(String body) {
                try {
                    org.json.JSONArray filas = new org.json.JSONArray(body);
                    int total = filas.length() > 0 ? filas.getJSONObject(0).optInt("cant_siguiendo", 0) : 0;
                    activity.runOnUiThread(() -> result.success(total));
                } catch (org.json.JSONException e) {
                    activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                }
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        }, false));
    }

    private void handleEstasSiguiendo(MethodCall call, MethodChannel.Result result) {
        Integer idSeguidor = call.argument("id_seguidor");
        Integer idSeguido  = call.argument("id_seguido");
        HttpClientManager.getInstance().get(
            "/rest/v1/seguidos_usuario?select=id_seguidor&id_seguidor=eq." + idSeguidor + "&id_seguido=eq." + idSeguido,
            HttpClientManager.simpleCallback(new CallbackCB() {
                @Override public void onSuccess(String body) {
                    try {
                        boolean siguiendo = new org.json.JSONArray(body).length() > 0;
                        activity.runOnUiThread(() -> result.success(siguiendo));
                    } catch (org.json.JSONException e) {
                        activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                    }
                }
                @Override public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            }, false)
        );
    }

    private void handleGetPerfilEditable(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        JSONObject body = new JSONObject();
        try {
            body.put("p_id", idUsuario);
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
            return;
        }
        RpcCallHelper.callAsync("obtener_perfil_editable", body, new CallbackCB() {
            @Override public void onSuccess(String response) {
                JSONObject fila = RpcCallHelper.firstOrNull(response);
                if (fila == null) {
                    activity.runOnUiThread(() -> result.error("NOT_FOUND", "Usuario no encontrado", null));
                    return;
                }
                try {
                    Usuario u = Mapper.jsonToUsuario(fila);
                    String json = Mapper.usuarioToEditJson(u).toString();
                    activity.runOnUiThread(() -> result.success(json));
                } catch (org.json.JSONException e) {
                    activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                }
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        });
    }


    private void handleSolicitarOtp(MethodCall call, MethodChannel.Result result) {
        String correo = call.argument("correo");
        if (correo == null || correo.trim().isEmpty()) {
            result.error("NEGOCIO", "Falta el correo.", null);
            return;
        }
        JSONObject body = new JSONObject();
        try {
            body.put("correo", correo.trim());
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
            return;
        }
        HttpClientManager.getInstance().post("/functions/v1/enviar-otp", body.toString(), new okhttp3.Callback() {
            @Override public void onFailure(okhttp3.Call call, java.io.IOException e) {
                activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
            }
            @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                if (response.isSuccessful()) {
                    activity.runOnUiThread(() -> result.success(true));
                } else {
                    int code = response.code();
                    String b = response.body() != null ? response.body().string() : "";
                    activity.runOnUiThread(() -> result.error("OTP_ERROR", "enviar-otp respondió " + code + ": " + b, null));
                }
            }
        });
    }

    private void handleVerificarOtp(MethodCall call, MethodChannel.Result result) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_correo", (String) call.argument("correo"));
            body.put("p_codigo", (String) call.argument("codigo"));
            RpcCallHelper.callAsync("verificar_otp", body, new CallbackCB() {
                @Override public void onSuccess(String response) {
                    boolean ok = Boolean.parseBoolean(response.trim());
                    activity.runOnUiThread(() -> result.success(ok));
                }
                @Override public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            });
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
        }
    }

    private void handleResetPass(MethodCall call, MethodChannel.Result result) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_correo", (String) call.argument("correo"));
            body.put("p_codigo", (String) call.argument("codigo"));
            body.put("p_nueva",  (String) call.argument("nueva"));
            RpcCallHelper.callAsync("reset_pass", body, new CallbackCB() {
                @Override public void onSuccess(String response) {
                    if (Boolean.parseBoolean(response.trim())) {
                        activity.runOnUiThread(() -> result.success(true));
                    } else {
                        activity.runOnUiThread(() -> result.error("RESET_FALLIDO", "El código no es válido o venció.", null));
                    }
                }
                @Override public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            });
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
        }
    }

    private void handleActualizarPerfilOtp(MethodCall call, MethodChannel.Result result) {
        try {
            Integer id = call.argument("id");
            String codigo = call.argument("codigo");
            java.util.Map<String, Object> datos = call.argument("datos");
            JSONObject body = new JSONObject();
            body.put("p_id", id);
            body.put("p_codigo", codigo);
            body.put("p_data", new JSONObject(datos));
            RpcCallHelper.callAsync("actualizar_perfil_otp", body, new CallbackCB() {
                @Override public void onSuccess(String response) {
                    try {
                        JSONObject obj = new JSONObject(response);
                        if (obj.optBoolean("ok", false)) {
                            activity.runOnUiThread(() -> result.success(true));
                        } else {
                            String err = obj.optString("error", "desconocido");
                            activity.runOnUiThread(() -> result.error("OTP_FALLIDO", err, null));
                        }
                    } catch (org.json.JSONException e) {
                        activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                    }
                }
                @Override public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            });
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
        }
    }


    private void handleSolicitarVerificacionCorreo(MethodCall call, MethodChannel.Result result) {
        String correo = call.argument("correo");
        if (correo == null || correo.trim().isEmpty()) {
            result.error("NEGOCIO", "Falta el correo.", null);
            return;
        }
        JSONObject body = new JSONObject();
        try {
            body.put("correo", correo.trim());
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
            return;
        }
        HttpClientManager.getInstance().post("/functions/v1/enviar-verificacion", body.toString(), new okhttp3.Callback() {
            @Override public void onFailure(okhttp3.Call call, java.io.IOException e) {
                activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
            }
            @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                if (response.isSuccessful()) {
                    activity.runOnUiThread(() -> result.success(true));
                } else {
                    int code = response.code();
                    String b = response.body() != null ? response.body().string() : "";
                    activity.runOnUiThread(() -> result.error("VERIF_ERROR", "enviar-verificacion respondió " + code + ": " + b, null));
                }
            }
        });
    }

    private void handleVerificarCodigoRegistro(MethodCall call, MethodChannel.Result result) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_correo", (String) call.argument("correo"));
            body.put("p_codigo", (String) call.argument("codigo"));
            RpcCallHelper.callAsync("verificar_codigo_registro", body, new CallbackCB() {
                @Override public void onSuccess(String response) {
                    boolean ok = Boolean.parseBoolean(response.trim());
                    activity.runOnUiThread(() -> result.success(ok));
                }
                @Override public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            });
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
        }
    }

    private void handleVerificarLinkRegistro(MethodCall call, MethodChannel.Result result) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_token", (String) call.argument("token"));
            RpcCallHelper.callAsync("verificar_link_registro", body, new CallbackCB() {
                @Override public void onSuccess(String response) {
                    boolean ok = Boolean.parseBoolean(response.trim());
                    activity.runOnUiThread(() -> result.success(ok));
                }
                @Override public void onError(String code, String message, Object details) {
                    activity.runOnUiThread(() -> result.error(code, message, details));
                }
            });
        } catch (org.json.JSONException e) {
            result.error("ERROR_JSON", e.getMessage(), null);
        }
    }

    private void responderUsuarioLimpio(String filaUsuarioJson, MethodChannel.Result result) {
        try {
            JSONObject fila = new JSONObject(filaUsuarioJson);
            Usuario u = Mapper.jsonToUsuario(fila);
            u.setId(fila.getInt("id"));
            String limpio = Mapper.usuarioToClientJson(u).toString();
            activity.runOnUiThread(() -> result.success(limpio));
        } catch (org.json.JSONException e) {
            activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
        }
    }
    private void handleBuscarUsuario(MethodCall call, MethodChannel.Result result){
        usuarioManager.buscarUsuario(
                call.argument("query"),
                bridgeData(result)
        );
    }
    private CallbackCB bridgeData(MethodChannel.Result result) {
        return new CallbackCB() {
            @Override
            public void onSuccess(String data) {
                activity.runOnUiThread(() -> result.success(data));
            }
            @Override
            public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        };
    }
}
