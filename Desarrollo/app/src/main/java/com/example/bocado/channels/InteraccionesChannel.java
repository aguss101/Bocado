package com.example.bocado.channels;
import android.app.Activity;
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
import okhttp3.Call;
import okhttp3.Response;
import org.json.JSONObject;

import java.io.IOException;
import java.lang.reflect.Method;

public class InteraccionesChannel {
    private static final String CHANNEL = "com.example.bocado/interacciones";
    private final Activity activity;
    private final UsuarioManager usuarioManager;

    public InteraccionesChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        this.usuarioManager = new UsuarioManager(new UsuarioDAO());

        new MethodChannel(messenger, CHANNEL)
                .setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "updateSeguido" -> handleUpdateSeguido(call, result);
            case "getSeguidos" -> handleGetSeguidos(call, result);
            case "toggleInteraction"-> handleToggleInteraction(call, result);
        }
    }

    // ── updateSeguido ───────────────────────────────────────────────────────────
    private void handleUpdateSeguido(MethodCall call, MethodChannel.Result result) {
        int idSeguidor = call.argument("id_seguidor");
        int idSeguido = call.argument("id_seguido");
        Boolean siguiendo = call.argument("siguiendo");

        usuarioManager.actualizarSeguido(idSeguidor, idSeguido, siguiendo, new CallbackCB() {
            @Override
            public void onSuccess(String data) {
                activity.runOnUiThread(() -> result.success(data));
            }
            @Override
            public void onError(String code, String message, Object details) {
                activity.runOnUiThread(()-> result.error(code,message,details));
            }
        });
    }
    // ── toggleInteraccion ─────────────────────────────────────────────────────
    private void handleToggleInteraction(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        Integer idReceta  = call.argument("id_receta");
        String tipo       = call.argument("tipo"); // "like" o "guardado"
        Boolean isAdding  = call.argument("is_adding"); // true si agrega, false si quita

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
}