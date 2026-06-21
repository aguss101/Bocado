package com.example.bocado.Channels;
import android.app.Activity;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.Managers.UsuarioManager;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import okhttp3.Call;
import okhttp3.Response;

import java.io.IOException;
import java.lang.reflect.Method;

public class InteractionsChannel {
    private static final String CHANNEL = "com.example.bocado/interacciones";
    private final Activity activity;
    private final UsuarioManager usuarioManager;

    public InteractionsChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        this.usuarioManager = new UsuarioManager(new UsuarioDAO());

        new MethodChannel(messenger, CHANNEL)
                .setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "updateSeguido" -> handleUpdateFollow(call, result);
            //case "getSeguidos" -> handleGetSeguidos(call, result); CORREGIR Agregando el Handle
            case "toggleInteraction" -> handleToggleInteraction(call, result);
            case "fetchComentarios" -> handleFetchComentarios(call, result);
            case "enviarComentario" -> handleEnviarComentario(call, result);
            default -> result.notImplemented();
        }
    }

    // ── updateSeguido ───────────────────────────────────────────────────────────
    private void handleUpdateFollow(MethodCall call, MethodChannel.Result result) {
        int idSeguidor = call.argument("id_seguidor");
        int idSeguido = call.argument("id_seguido");
        Boolean siguiendo = call.argument("siguiendo");

        usuarioManager.updatefollow(idSeguidor, idSeguido, siguiendo, new CallbackCB() {
            @Override
            public void onSuccess(String data) {
                activity.runOnUiThread(() -> result.success(data));
            }

            @Override
            public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        });
    }

    // ── toggleInteraccion ─────────────────────────────────────────────────────
    private void handleToggleInteraction(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        Integer idReceta = call.argument("id_receta");
        String tipo = call.argument("tipo"); // "like" o "guardado"
        Boolean isAdding = call.argument("is_adding"); // true si agrega, false si quita

        if (isAdding != null && isAdding) {
            String jsonBody = String.format(
                    "{\"id_usuario\": %d, \"id_receta\": %d, \"tipo_interaccion\": \"%s\"}",
                    idUsuario, idReceta, tipo
            );

            HttpClientManager.getInstance().post(
                    "/rest/v1/interacciones_usuario",
                    jsonBody,
                    new okhttp3.Callback() {
                        @Override
                        public void onFailure(Call call, IOException e) {
                            activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                        }

                        @Override
                        public void onResponse(Call call, Response response) throws IOException {
                            if (response.isSuccessful()) {
                                activity.runOnUiThread(() -> result.success(true));
                            } else {
                                activity.runOnUiThread(() -> result.error("API_ERROR", "Fallo insert: " + response.code(), null));
                            }
                        }
                    }
            );

        } else {
            String endpoint = String.format(
                    "/rest/v1/interacciones_usuario?id_usuario=eq.%d&id_receta=eq.%d&tipo_interaccion=eq.%s",
                    idUsuario, idReceta, tipo
            );

            HttpClientManager.getInstance().delete(
                    endpoint,
                    new okhttp3.Callback() {
                        @Override
                        public void onFailure(Call call, IOException e) {
                            activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                        }

                        @Override
                        public void onResponse(Call call, Response response) throws IOException {
                            if (response.isSuccessful()) {
                                activity.runOnUiThread(() -> result.success(true));
                            } else {
                                activity.runOnUiThread(() -> result.error("API_ERROR", "Fallo delete: " + response.code(), null));
                            }
                        }
                    }
            );
        }
    }

    private void handleFetchComentarios(MethodCall call, MethodChannel.Result result) {
        Integer recetaId = call.argument("recetaId");

        if (recetaId == null) {
            result.error("ARGUMENT_ERROR", "El recetaId es nulo", null);
            return;
        }

        HttpClientManager.getInstance().get("/rest/v1/vista_comentarios_recetas?id_receta=eq." + recetaId, new okhttp3.Callback() {
            @Override
            public void onFailure(okhttp3.Call call, java.io.IOException e) {
                new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
                    result.error("NETWORK_ERROR", e.getMessage(), null);
                });
            }

            @Override
            public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                if (response.isSuccessful() && response.body() != null) {
                    final String jsonResponse = response.body().string();

                    new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
                        result.success(jsonResponse);
                    });
                } else {
                    new android.os.Handler(android.os.Looper.getMainLooper()).post(() -> {
                        result.error("HTTP_ERROR", "Código: " + response.code(), null);
                    });
                }
            }
        });
    }
    private void handleEnviarComentario(MethodCall call, MethodChannel.Result result) {
        Integer idReceta = call.argument("id_receta");
        Integer idUsuario = call.argument("id_usuario");
        String comentario = call.argument("comentario");
        Integer idPadre = call.argument("id_comentario_padre");

        if (idReceta == null || idUsuario == null || comentario == null) {
            result.error("ARGUMENT_ERROR", "Faltan datos obligatorios", null);
            return;
        }

        org.json.JSONObject json = new org.json.JSONObject();
        try {
            json.put("p_id_receta", idReceta);
            json.put("p_id_usuario", idUsuario);
            json.put("p_comentario", comentario);
            json.put("p_id_comentario_padre", idPadre == null ? org.json.JSONObject.NULL : idPadre);
            json.put("p_calificacion", org.json.JSONObject.NULL);
        } catch (org.json.JSONException e) {
            result.error("JSON_ERROR", "Error formateando los datos", null);
            return;
        }

        String jsonBody = json.toString();

        HttpClientManager.getInstance().post(
                "/rest/v1/rpc/agregar_comentario",
                jsonBody,
                new okhttp3.Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                    }

                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        if (response.isSuccessful()) {
                            activity.runOnUiThread(() -> result.success(true));
                        } else {
                            String errorBody = "Sin detalles";
                            if (response.body() != null) {
                                errorBody = response.body().string();
                            }
                            final String finalError = errorBody;
                            activity.runOnUiThread(() -> result.error("API_ERROR", "Fallo 400: " + finalError, null));
                        }
                    }
                }
        );
    }
}