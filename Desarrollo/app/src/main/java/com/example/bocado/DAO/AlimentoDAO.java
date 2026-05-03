package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Managers.HttpClientManager;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.*;

public class AlimentoDAO {

    private static final String BASE_RPC = "/rest/v1/rpc/";
    private static void callRpcAsync(String rpc, JSONObject body, CallbackCB cb) {
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
    private static String callRpcSync(String rpc, JSONObject body) throws Exception {
        okhttp3.OkHttpClient client = HttpClientManager.getInstance().getRawClient();

        okhttp3.Request request = HttpClientManager.getInstance()
                .buildPostRequest(BASE_RPC + rpc, body.toString());

        try (Response response = client.newCall(request).execute()) {
            String bodyRes = response.body() != null ? response.body().string() : "";

            if (!response.isSuccessful()) {
                throw new Exception(bodyRes);
            }

            return bodyRes;
        }
    }
    private static List<Map<String, Object>> parseLista(String response) throws Exception {
        JSONArray array = new JSONArray(response);
        List<Map<String, Object>> lista = new ArrayList<>();

        for (int i = 0; i < array.length(); i++) {
            JSONObject obj = array.getJSONObject(i);

            Map<String, Object> item = new HashMap<>();
            item.put("id", obj.getInt("id"));
            item.put("nombre", obj.getString("nombre"));
            item.put("proteinas", obj.optDouble("proteinas", 0));
            item.put("carbohidratos", obj.optDouble("carbohidratos", 0));
            item.put("grasas", obj.optDouble("grasas", 0));

            lista.add(item);
        }

        return lista;
    }

    private static JSONObject firstOrNull(String response) throws Exception {
        JSONArray array = new JSONArray(response);
        return array.length() > 0 ? array.getJSONObject(0) : null;
    }
    public static List<Map<String, Object>> ListarParaFlutter() throws Exception {
        String response = callRpcSync("listar_alimentos", new JSONObject());
        return parseLista(response);
    }
    public static int CrearSimple(String nombre, int idUsuario) throws Exception {
        JSONObject json = new JSONObject();
        json.put("p_nombre", nombre);
        json.put("p_id_usuario", idUsuario);

        String response = callRpcSync("crear_alimento_simple", json);

        return Integer.parseInt(response);
    }
    public static void Crear(JSONObject alimentoJson, CallbackCB cb) throws JSONException {
        JSONObject json = new JSONObject();
        json.put("p_data", alimentoJson);

        callRpcAsync("crear_alimento", json, new CallbackCB() {
            @Override
            public void onSuccess(String response) {
                try {
                    JSONObject obj = firstOrNull(response);
                    if (obj != null) {
                        cb.onSuccess(obj.toString());
                    } else {
                        cb.onError("ERROR_CREATE", "No se pudo crear", null);
                    }
                } catch (Exception e) {
                    cb.onError("ERROR_PARSE", e.getMessage(), null);
                }
            }

            @Override
            public void onError(String code, String msg, Object data) {
                cb.onError(code, msg, data);
            }
        });
    }
}