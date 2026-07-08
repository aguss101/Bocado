package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.Interfaces.IInteraccion;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.RpcCallHelper;
import com.example.bocado.Managers.HttpClientManager;

import org.json.JSONObject;

public class InteraccionDAO implements IInteraccion {

    private static final String TABLA = "/rest/v1/interacciones_usuario";

    @Override
    public void toggleInteraccion(int idUsuario, int idReceta, String tipo, boolean isAdding, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id_usuario", idUsuario);
            json.put("p_id_receta", idReceta);
            json.put("p_tipo", tipo);
            json.put("p_agregar", isAdding);
            RpcCallHelper.callAsync("toggle_interaccion", json, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando la interacción: " + e.getMessage(), null);
        }
    }

    @Override
    public void fetchMisInteracciones(int idUsuario, int idReceta, CallbackCB cb) {
        HttpClientManager.getInstance().get(
                TABLA + "?select=tipo_interaccion&id_usuario=eq." + idUsuario + "&id_receta=eq." + idReceta,
                HttpClientManager.simpleCallback(cb));
    }

    @Override
    public void fetchComentarios(int idReceta, int idUsuario, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id_receta", idReceta);
            json.put("p_id_usuario", idUsuario);
            RpcCallHelper.callAsync("obtener_comentarios", json, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando la consulta: " + e.getMessage(), null);
        }
    }

    @Override
    public void enviarComentario(int idReceta, int idUsuario, String comentario, Integer idPadre, Double calificacion, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id_receta", idReceta);
            json.put("p_id_usuario", idUsuario);
            json.put("p_comentario", comentario);
            json.put("p_id_comentario_padre", idPadre == null ? JSONObject.NULL : idPadre);
            json.put("p_calificacion", calificacion == null ? JSONObject.NULL : calificacion);
            RpcCallHelper.callAsync("agregar_comentario", json, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando el comentario: " + e.getMessage(), null);
        }
    }

}
