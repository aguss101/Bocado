package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.RpcCallHelper;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.List;
import java.util.Map;

public class RecetaDAO {

    public void create(Map<String, Object> args, CallbackCB callback) {
        try {
            JSONObject recetaJson = new JSONObject();
            // Datos básicos
            recetaJson.put("id_usuario", args.get("id_usuario"));
            recetaJson.put("nombre", args.get("nombre"));
            recetaJson.put("calorias_totales", args.get("calorias_totales"));
            recetaJson.put("porciones", args.get("porciones"));
            recetaJson.put("porciones_peso", args.get("porciones_peso"));
            recetaJson.put("id_dificultad", args.get("id_dificultad"));
            recetaJson.put("precio", args.get("precio"));
            recetaJson.put("visibilidad", args.get("visibilidad"));
            recetaJson.put("es_borrador", args.get("es_borrador"));

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
}
