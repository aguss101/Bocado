package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.RpcCallHelper;
import com.example.bocado.Managers.HttpClientManager;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

public class RecetaDAO {

    private static final String VISTA = "/rest/v1/vistas_recetas_macros";

    public void feedAleatorio(String seed, int limit, int offset, Integer viewerId, CallbackCB cb) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_seed", seed != null ? seed : "0");
            body.put("p_limit", limit);
            body.put("p_offset", offset);
            body.put("p_viewer_id", viewerId != null ? viewerId : JSONObject.NULL);
            HttpClientManager.getInstance().post("/rest/v1/rpc/feed_aleatorio", body.toString(), restCallback(cb));
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando el feed: " + e.getMessage(), null);
        }
    }

    public void listarPorUsuario(int idUsuario, Integer limit, Integer offset, CallbackCB cb) {
        String url = VISTA + "?select=*&id_usuario=eq." + idUsuario + paginar(limit, offset);
        HttpClientManager.getInstance().get(url, restCallback(cb));
    }

    public void misRecetasCompleto(int idUsuario, CallbackCB cb) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_id_usuario", idUsuario);
            HttpClientManager.getInstance().post("/rest/v1/rpc/mis_recetas_completo", body.toString(), restCallback(cb));
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando la consulta: " + e.getMessage(), null);
        }
    }

    public void listarGuardados(int idUsuario, Integer limit, Integer offset, CallbackCB cb) {
        String url = VISTA + "?select=*,interacciones_usuario!inner(id_usuario,tipo_interaccion)"
                + "&interacciones_usuario.id_usuario=eq." + idUsuario
                + "&interacciones_usuario.tipo_interaccion=eq.save"
                + paginar(limit, offset);
        HttpClientManager.getInstance().get(url, restCallback(cb));
    }

    private String paginar(Integer limit, Integer offset) {
        if (limit == null) return "";
        return "&order=id_receta.desc&limit=" + limit + "&offset=" + (offset != null ? offset : 0);
    }

    public void obtenerDetalle(int idReceta, CallbackCB cb) {
        try {
            JSONObject body = new JSONObject();
            body.put("p_id_receta", idReceta);
            HttpClientManager.getInstance().post("/rest/v1/rpc/obtener_detalle_completo", body.toString(), restCallback(cb));
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando la consulta: " + e.getMessage(), null);
        }
    }

    private Callback restCallback(CallbackCB cb) {
        return new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                cb.onError(ErrorCode.NETWORK_ERROR, e.getMessage(), null);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String body = response.body() != null ? response.body().string() : "[]";
                if (response.isSuccessful()) {
                    cb.onSuccess(body);
                } else {
                    cb.onError(ErrorCode.ERROR_API, "Error " + response.code() + ": " + body, null);
                }
            }
        };
    }

    public void create(Map<String, Object> args, CallbackCB callback) {
        try {
            JSONObject recetaJson = new JSONObject();
            recetaJson.put("id_usuario", args.get("id_usuario"));
            recetaJson.put("nombre", args.get("nombre"));
            recetaJson.put("calorias_totales", args.get("calorias_totales"));
            recetaJson.put("porciones", args.get("porciones"));
            recetaJson.put("porciones_peso", args.get("porciones_peso"));
            recetaJson.put("id_dificultad", args.get("id_dificultad"));
            recetaJson.put("precio", args.get("precio"));
            recetaJson.put("visibilidad", args.get("visibilidad"));
            recetaJson.put("es_borrador", args.get("es_borrador"));
            recetaJson.put("tiempo_coccion", args.get("tiempo_coccion"));
            recetaJson.put("breve_descripcion", args.get("breve_descripcion"));

            if (args.containsKey("fotos")) {
                List<String> listaFotos = (List<String>) args.get("fotos");
                String fotosConcatenadas = String.join("|", listaFotos);
                recetaJson.put("foto", fotosConcatenadas);
            }
            if (args.containsKey("instrucciones")) {
                List<String> listaPasos = (List<String>) args.get("instrucciones");
                String instruccionesConcatenadas = String.join("|", listaPasos);
                recetaJson.put("instrucciones", instruccionesConcatenadas);
            }
            if (args.containsKey("tags_ids")) {
                recetaJson.put("tags_ids", new JSONArray((List<?>) args.get("tags_ids")));
            }
            if (args.containsKey("ingredientes")) {
                Object ingredientesObj = args.get("ingredientes");
                if (ingredientesObj instanceof List) {
                    recetaJson.put("ingredientes", new JSONArray((List<?>) ingredientesObj));
                } else {
                    recetaJson.put("ingredientes", ingredientesObj);
                }
            }

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
            JSONObject recetaJson = new JSONObject();
            recetaJson.put("id", args.get("id"));
            recetaJson.put("id_usuario", args.get("id_usuario"));
            recetaJson.put("nombre", args.get("nombre"));
            recetaJson.put("calorias_totales", args.get("calorias_totales"));
            recetaJson.put("porciones", args.get("porciones"));
            recetaJson.put("porciones_peso", args.get("porciones_peso"));
            recetaJson.put("id_dificultad", args.get("id_dificultad"));
            recetaJson.put("precio", args.get("precio"));
            recetaJson.put("visibilidad", args.get("visibilidad"));
            recetaJson.put("es_borrador", args.get("es_borrador"));
            recetaJson.put("tiempo_coccion", args.get("tiempo_coccion"));
            recetaJson.put("breve_descripcion", args.get("breve_descripcion"));

            if (args.containsKey("fotos")) {
                List<String> listaFotos = (List<String>) args.get("fotos");
                String fotosConcatenadas = String.join("|", listaFotos);
                recetaJson.put("foto", fotosConcatenadas);
            }
            if (args.containsKey("instrucciones")) {
                List<String> listaPasos = (List<String>) args.get("instrucciones");
                String instruccionesConcatenadas = String.join("|", listaPasos);
                recetaJson.put("instrucciones", instruccionesConcatenadas);
            }
            if (args.containsKey("tags_ids")) {
                recetaJson.put("tags_ids", new JSONArray((List<?>) args.get("tags_ids")));
            }
            if (args.containsKey("ingredientes")) {
                Object ingredientesObj = args.get("ingredientes");
                if (ingredientesObj instanceof List) {
                    recetaJson.put("ingredientes", new JSONArray((List<?>) ingredientesObj));
                } else {
                    recetaJson.put("ingredientes", ingredientesObj);
                }
            }

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
        org.json.JSONObject payload = new org.json.JSONObject();
        try {
            payload.put("p_id_receta", idReceta);
            payload.put("p_id_usuario", idUsuario);
        } catch (org.json.JSONException e) {
            cb.onError("JSON_ERROR", "Error al construir los datos: " + e.getMessage(), null);
            return;
        }

        HttpClientManager.getInstance().post("/rest/v1/rpc/eliminar_receta_fisico", payload.toString(), new okhttp3.Callback() {
            @Override
            public void onFailure(okhttp3.Call call, java.io.IOException e) {
                cb.onError("NETWORK_ERROR", e.getMessage(), null);
            }

            @Override
            public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                String body = response.body() != null ? response.body().string() : "";
                if (!response.isSuccessful()) {
                    cb.onError("DB_ERROR", body.isEmpty() ? "Error HTTP: " + response.code() : body, null);
                } else {
                    cb.onSuccess(body);
                }
            }
        });
    }

    public void buscarReceta(String query, CallbackCB cb){
        String url = VISTA + "?nombre_receta=ilike.*" + query + "*&limit=20";
        HttpClientManager.getInstance().get(url, restCallback(cb));
    }

}
