package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.Interfaces.IInteraccion;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.RpcCallHelper;
import com.example.bocado.Managers.HttpClientManager;

import org.json.JSONObject;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

public class InteraccionDAO implements IInteraccion {

    private static final String TABLA = "/rest/v1/interacciones_usuario";
    private static final String VISTA_COMENTARIOS = "/rest/v1/vista_comentarios_recetas";

    @Override
    public void toggleInteraccion(int idUsuario, int idReceta, String tipo, boolean isAdding, CallbackCB cb) {
        if (isAdding) {
            try {
                JSONObject json = new JSONObject();
                json.put("id_usuario", idUsuario);
                json.put("id_receta", idReceta);
                json.put("tipo_interaccion", tipo);
                HttpClientManager.getInstance().post(TABLA, json.toString(), restCallbackIdempotente(cb));
            } catch (Exception e) {
                cb.onError(ErrorCode.ERROR_JSON, "Error armando la interacción: " + e.getMessage(), null);
            }
        } else {
            String endpoint = TABLA
                    + "?id_usuario=eq." + idUsuario
                    + "&id_receta=eq." + idReceta
                    + "&tipo_interaccion=eq." + tipo;
            HttpClientManager.getInstance().delete(endpoint, restCallback(cb));
        }
    }

    @Override
    public void fetchMisInteracciones(int idUsuario, int idReceta, CallbackCB cb) {
        HttpClientManager.getInstance().get(
                TABLA + "?select=tipo_interaccion&id_usuario=eq." + idUsuario + "&id_receta=eq." + idReceta,
                restCallback(cb));
    }

    @Override
    public void fetchComentarios(int idReceta, CallbackCB cb) {
        HttpClientManager.getInstance().get(
                VISTA_COMENTARIOS + "?id_receta=eq." + idReceta, restCallback(cb));
    }

    @Override
    public void enviarComentario(int idReceta, int idUsuario, String comentario, Integer idPadre, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id_receta", idReceta);
            json.put("p_id_usuario", idUsuario);
            json.put("p_comentario", comentario);
            json.put("p_id_comentario_padre", idPadre == null ? JSONObject.NULL : idPadre);
            json.put("p_calificacion", JSONObject.NULL);
            RpcCallHelper.callAsync("agregar_comentario", json, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando el comentario: " + e.getMessage(), null);
        }
    }

    /** Mapea la respuesta REST de OkHttp al CallbackCB del proyecto. No toca UI. */
    private Callback restCallback(CallbackCB cb) {
        return new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                cb.onError(ErrorCode.NETWORK_ERROR, e.getMessage(), null);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String body = response.body() != null ? response.body().string() : "";
                if (response.isSuccessful()) {
                    cb.onSuccess(body);
                } else {
                    cb.onError(ErrorCode.ERROR_API, "Error " + response.code() + ": " + body, null);
                }
            }
        };
    }

    /**
     * Igual que restCallback pero trata el 409 (clave duplicada) como éxito: agregar
     * una interacción que ya existe es idempotente — el estado deseado ya se cumple.
     * Evita el "Error al guardar" cuando el estado en pantalla quedó desfasado del de la BD.
     */
    private Callback restCallbackIdempotente(CallbackCB cb) {
        return new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                cb.onError(ErrorCode.NETWORK_ERROR, e.getMessage(), null);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String body = response.body() != null ? response.body().string() : "";
                if (response.isSuccessful() || response.code() == 409) {
                    cb.onSuccess(body);
                } else {
                    cb.onError(ErrorCode.ERROR_API, "Error " + response.code() + ": " + body, null);
                }
            }
        };
    }
}
