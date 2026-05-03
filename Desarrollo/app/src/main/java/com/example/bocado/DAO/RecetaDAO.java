package com.example.bocado.DAO;

import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.DAO.Interfaces.CallbackCB;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

import org.json.JSONObject;

import java.io.IOException;
import java.util.Map;

public class RecetaDAO {

    private static final String BASE_RPC = "/rest/v1/rpc/";
    private void callRpc(String rpc, JSONObject body, CallbackCB cb) {
        HttpClientManager.getInstance().post(
                BASE_RPC + rpc,
                body.toString(),
                new Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        cb.onError("NETWORK_ERROR", e.getMessage(), null);
                    }

                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        String resBody = response.body() != null ? response.body().string() : "";

                        if (response.isSuccessful()) {
                            cb.onSuccess(resBody);
                        } else {
                            cb.onError("ERROR_API", resBody, null);
                        }
                    }
                }
        );
    }
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

            callRpc("crear_receta", body, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    try {
                        JSONObject obj = new JSONObject(response);

                        if (obj.getBoolean("ok")) {
                            callback.onSuccess(obj.getJSONObject("data").toString());
                        } else {
                            callback.onError("ERROR_RECETA", "No se pudo crear la receta", null);
                        }

                    } catch (Exception e) {
                        callback.onError("PARSE_ERROR", e.getMessage(), null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    callback.onError(code, msg, data);
                }
            });

        } catch (Exception e) {
            callback.onError("ERROR_CRITICO", e.getMessage(), null);
        }
    }
}