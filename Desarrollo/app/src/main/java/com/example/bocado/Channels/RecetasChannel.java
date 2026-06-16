package com.example.bocado.Channels;

import android.app.Activity;

import com.example.bocado.DAO.AlimentoDAO;
import com.example.bocado.DAO.EtiquetaDAO;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.Managers.RecetaManager;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import okhttp3.Call;
import okhttp3.Response;

public class RecetasChannel {

    private static final String CHANNEL = "com.example.bocado/recetas";
    private final Activity activity;

    public RecetasChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        new MethodChannel(messenger, CHANNEL)
                .setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "getAlimentos"    -> handleGetAlimento(result);
            case "addAlimento"     -> handleAddAlimento(call, result);
            case "saveReceta"      -> handleSaveReceta(call, result);
            case "getRecetas"      -> handleGetRecetas(result);
            case "getRecetasUsuario" -> handleGetRecetasUsuario(call, result);
            case "getRecetaDetalle"-> handleGetRecetaDetalle(call, result);
            case "getGuardadosUsuario" -> handleGetSaveUser(call, result);
            case "contarRecetas"   -> handleContarRecetas(call, result);
            case "getEtiquetas" -> handleGetEtiquetas(call, result);

            default                -> result.notImplemented();
        }
    }

    private void handleGetEtiquetas(MethodCall call,MethodChannel.Result result) {
        new Thread(() -> {
            try {
                int userId = call.argument("id_usuario");
                List<Map<String, Object>> lista = EtiquetaDAO.listarMisEtiquetas(userId);
                activity.runOnUiThread(() -> result.success(lista));
            } catch (Exception e) {
                activity.runOnUiThread(() -> result.error("DB_ERROR", e.getMessage(), null));
            }
        }).start();
    }

    // ── getAlimentos ──────────────────────────────────────────────────────────
    private void handleGetAlimento(MethodChannel.Result result) {
        new Thread(() -> {
            try {
                List<Map<String, Object>> lista = AlimentoDAO.listarParaFlutter();
                activity.runOnUiThread(() -> result.success(lista));
            } catch (Exception e) {
                activity.runOnUiThread(() -> result.error("DB_ERROR", e.getMessage(), null));
            }
        }).start();
    }

    // ── addAlimento ───────────────────────────────────────────────────────────
    private void handleAddAlimento(MethodCall call, MethodChannel.Result result) {
        String nombre     = call.argument("nombre");
        Integer idUsuario = call.argument("id_usuario");

        new Thread(() -> {
            try {
                int nuevoId = AlimentoDAO.crearSimple(nombre, idUsuario);
                Map<String, Object> res = new HashMap<>();
                res.put("id", nuevoId);
                activity.runOnUiThread(() -> result.success(res));
            } catch (Exception e) {
                activity.runOnUiThread(() -> result.error("DB_ERROR", e.getMessage(), null));
            }
        }).start();
    }

    // ── saveReceta ────────────────────────────────────────────────────────────
    private void handleSaveReceta(MethodCall call, MethodChannel.Result result) {
        Map<String, Object> args = call.arguments();

        RecetaManager.getInstance().create(args, new MethodChannel.Result() {
            @Override
            public void success(Object data) {
                activity.runOnUiThread(() -> result.success(data));
            }
            @Override
            public void error(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
            @Override
            public void notImplemented() {
                activity.runOnUiThread(result::notImplemented);
            }
        });
    }

    // ── getRecetasUsuario ────────────────────────────────────────────────────────────
    private void handleGetRecetasUsuario(MethodCall call, MethodChannel.Result result) {
        Integer usuarioId = call.argument("usuarioId");

        HttpClientManager.getInstance().get(
                "/rest/v1/vistas_recetas_macros?select=*&id_usuario=eq." + usuarioId,
                new okhttp3.Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                    }
                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        String body = response.body() != null ? response.body().string() : "[]";
                        activity.runOnUiThread(() -> result.success(body));
                    }
                }
        );
    }

    // ── getGuardadosUsuario ────────────────────────────────────────────────────────────
    private void handleGetSaveUser(MethodCall call, MethodChannel.Result result) {
        Integer usuarioId = call.argument("usuarioId");

        HttpClientManager.getInstance().get(
                "/rest/v1/vistas_recetas_macros?select=*,interacciones_usuario!inner(id_usuario,tipo_interaccion)&interacciones_usuario.id_usuario=eq." + usuarioId + "&interacciones_usuario.tipo_interaccion=eq.save",
                new okhttp3.Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                    }
                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        String body = response.body() != null ? response.body().string() : "[]";
                        activity.runOnUiThread(() -> result.success(body));
                    }
                }
        );
    }

    // ── contarRecetas (lectura O(1) del contador mantenido por trigger) ──────────
    private void handleContarRecetas(MethodCall call, MethodChannel.Result result) {
        Integer usuarioId = call.argument("usuarioId");
        HttpClientManager.getInstance().get(
                "/rest/v1/estadisticas_usuario?select=cant_recetas&id_usuario=eq." + usuarioId,
                new okhttp3.Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                    }
                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        String body = response.body() != null ? response.body().string() : "[]";
                        try {
                            org.json.JSONArray filas = new org.json.JSONArray(body);
                            int total = filas.length() > 0 ? filas.getJSONObject(0).optInt("cant_recetas", 0) : 0;
                            activity.runOnUiThread(() -> result.success(total));
                        } catch (org.json.JSONException e) {
                            activity.runOnUiThread(() -> result.error("ERROR_JSON", e.getMessage(), null));
                        }
                    }
                }
        );
    }

    // ── getRecetas ────────────────────────────────────────────────────────────
    private void handleGetRecetas(MethodChannel.Result result) {
        HttpClientManager.getInstance().get(
                "/rest/v1/vistas_recetas_macros?select=*",
                new okhttp3.Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                    }
                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        String body = response.body() != null ? response.body().string() : "[]";
                        activity.runOnUiThread(() -> result.success(body));
                    }
                }
        );
    }

    // ── getRecetaDetalle ──────────────────────────────────────────────────────
    private void handleGetRecetaDetalle(MethodCall call, MethodChannel.Result result) {
        Integer id = call.argument("id");
        String endpoint = "/rest/v1/recetas"
                + "?select=*,usuarios!UR(nombre,foto),recetas_alimentos(cantidad,alimentos(nombre))"
                + "&id=eq." + id;

        HttpClientManager.getInstance().get(endpoint, new okhttp3.Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                activity.runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
            }
            @Override
            public void onResponse(Call call, Response response) throws IOException {
                if (response.isSuccessful()) {
                    String body = response.body() != null ? response.body().string() : "[]";
                    activity.runOnUiThread(() -> result.success(body));
                } else {
                    String detalle = response.body() != null ? response.body().string() : "Sin detalles";
                    activity.runOnUiThread(() -> result.error(
                            "API_ERROR",
                            "Fallo Supabase. Detalle: " + detalle,
                            null
                    ));
                }
            }
        });
    }
}