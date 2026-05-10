package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.RpcCallHelper;

import org.json.JSONObject;

import java.util.Map;

public class RecetaDAO {

    public void crear(Map<String, Object> args, CallbackCB callback) {
        try {
            JSONObject recetaJson = new JSONObject();
            recetaJson.put("id_usuario", args.get("id_usuario"));
            recetaJson.put("nombre", args.get("nombre"));
            recetaJson.put("calorias_totales", args.get("calorias_totales"));
            recetaJson.put("porciones", args.get("porciones"));
            recetaJson.put("instrucciones", args.get("instrucciones"));
            recetaJson.put("precio", args.containsKey("precio") ? args.get("precio") : 0);

            if (args.containsKey("ingredientes")) {
                recetaJson.put("ingredientes", args.get("ingredientes"));
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
