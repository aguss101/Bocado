package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.Mapper;
import com.example.bocado.Estaticos.RpcCallHelper;
import com.example.bocado.Managers.HttpClientManager;

import org.json.JSONObject;

import java.util.Map;

public class RecetaDAO {

    private static final String VISTA = "/rest/v1/vistas_recetas_feed";

    public void feedAleatorio(String seed, int limit, int offset, Integer viewerId, CallbackCB cb) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_seed", seed != null ? seed : "0");
            body.put("p_limit", limit);
            body.put("p_offset", offset);
            body.put("p_viewer_id", viewerId != null ? viewerId : JSONObject.NULL);
            RpcCallHelper.callAsync("feed_aleatorio", body, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando el feed: " + e.getMessage(), null);
        }
    }

    public void listarPorUsuario(int idUsuario, Integer limit, Integer offset, CallbackCB cb) {
        String url = VISTA + "?select=*&id_usuario=eq." + idUsuario + "&activo=eq.true&visibilidad=eq.true"
                + HttpClientManager.paginar("id_receta", limit, offset);
        HttpClientManager.getInstance().get(url, HttpClientManager.simpleCallback(cb));
    }

    public void misRecetasCompleto(int idUsuario, CallbackCB cb) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_id_usuario", idUsuario);
            RpcCallHelper.callAsync("mis_recetas_completo", body, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando la consulta: " + e.getMessage(), null);
        }
    }

    public void listarGuardados(int idUsuario, Integer limit, Integer offset, CallbackCB cb) {
        String url = VISTA + "?select=*,interacciones_usuario!inner(id_usuario,tipo_interaccion)"
                + "&interacciones_usuario.id_usuario=eq." + idUsuario
                + "&interacciones_usuario.tipo_interaccion=eq.save"
                + HttpClientManager.paginar("id_receta", limit, offset);
        HttpClientManager.getInstance().get(url, HttpClientManager.simpleCallback(cb));
    }

    public void obtenerDetalle(int idReceta, CallbackCB cb) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_id_receta", idReceta);
            RpcCallHelper.callAsync("obtener_detalle_completo", body, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando la consulta: " + e.getMessage(), null);
        }
    }

    public void create(Map<String, Object> args, CallbackCB callback) {
        try {
            JSONObject recetaJson = Mapper.recetaToJson(args);

            JSONObject body = new JSONObject();
            body.put("p_data", recetaJson);

            RpcCallHelper.callAsync("crear_receta", body, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    try {
                        JSONObject obj = new JSONObject(response);
                        if (obj.getBoolean("ok")) {
                            callback.onSuccess(obj.getJSONObject("data").toString());
                        } else {
                            callback.onError(ErrorCode.ERROR_RECETA, "No se pudo crear la receta", null);
                        }
                    } catch (Exception e) {
                        callback.onError(ErrorCode.PARSE_ERROR, e.getMessage(), null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    callback.onError(code, msg, data);
                }
            });

        } catch (Exception e) {
            callback.onError(ErrorCode.ERROR_INTERNO, e.getMessage(), null);
        }
    }
    public void getById(int idReceta, CallbackCB callback) {
        try {
            JSONObject data = new JSONObject();
            data.put("id_receta", idReceta);

            JSONObject body = new JSONObject();
            body.put("p_data", data);

            RpcCallHelper.callAsync("obtener_receta_por_id", body, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    try {
                        JSONObject obj = new JSONObject(response);
                        if (obj.getBoolean("ok")) {
                            callback.onSuccess(obj.getJSONObject("data").toString());
                        } else {
                            callback.onError(ErrorCode.ERROR_RECETA, "Receta no encontrada", null);
                        }
                    } catch (Exception e) {
                        callback.onError(ErrorCode.PARSE_ERROR, e.getMessage(), null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    callback.onError(code, msg, data);
                }
            });
        } catch (Exception e) {
            callback.onError(ErrorCode.ERROR_INTERNO, e.getMessage(), null);
        }
    }
    public void update(Map<String, Object> args, CallbackCB callback) {
        try {
            JSONObject recetaJson = Mapper.recetaToJson(args);
            recetaJson.put("id", args.get("id"));

            JSONObject body = new JSONObject();
            body.put("p_data", recetaJson);

            RpcCallHelper.callAsync("actualizar_receta", body, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    try {
                        JSONObject obj = new JSONObject(response);
                        if (obj.getBoolean("ok")) {
                            callback.onSuccess(obj.getJSONObject("data").toString());
                        } else {
                            callback.onError(ErrorCode.ERROR_RECETA, "No se pudo crear la receta", null);
                        }
                    } catch (Exception e) {
                        callback.onError(ErrorCode.PARSE_ERROR, e.getMessage(), null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    callback.onError(code, msg, data);
                }
            });

        } catch (Exception e) {
            callback.onError(ErrorCode.ERROR_INTERNO, e.getMessage(), null);
        }
    }

    public void eliminarReceta(int idReceta, int idUsuario, CallbackCB cb) {
        try {
            JSONObject payload = new JSONObject();
            payload.put("p_id_receta", idReceta);
            payload.put("p_id_usuario", idUsuario);
            RpcCallHelper.callAsync("eliminar_receta_fisico", payload, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error al construir los datos: " + e.getMessage(), null);
        }
    }
    public void buscarReceta(String query, CallbackCB cb){
        String url = VISTA + "?or=(nombre_receta.ilike.*" + query + "*,etiquetas_texto.ilike.*" + query + "*)&activo=eq.true&visibilidad=eq.true&limit=20";
        HttpClientManager.getInstance().get(url, HttpClientManager.simpleCallback(cb));
    }

}
