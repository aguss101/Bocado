package com.example.bocado.Estaticos;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Managers.HttpClientManager;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

public class RpcCallHelper {

    private static final String BASE_RPC = "/rest/v1/rpc/";

    /** Llamada RPC asíncrona — OkHttp gestiona su propio pool de threads. */
    public static void callAsync(String function, JSONObject body, CallbackCB cb) {
        HttpClientManager.getInstance().post(BASE_RPC + function, body.toString(), new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                cb.onError(ErrorCode.NETWORK_ERROR, "Error de red: " + e.getMessage(), null);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String resBody = response.body() != null ? response.body().string() : "";
                if (response.isSuccessful()) {
                    cb.onSuccess(resBody);
                } else {
                    // PostgREST devuelve {"code","message","details","hint"}. Extraemos
                    // un mensaje legible y detectamos el duplicado (SQLSTATE 23505)
                    // para no mostrarle JSON crudo al usuario.
                    String code = ErrorCode.ERROR_API;
                    String msg = resBody;
                    try {
                        JSONObject err = new JSONObject(resBody);
                        if (err.has("message") && !err.isNull("message")) {
                            msg = err.getString("message");
                        }
                        if ("23505".equals(err.optString("code"))) {
                            code = ErrorCode.DUPLICADO;
                        }
                    } catch (Exception ignore) {
                        // No era JSON → dejamos el body crudo como mensaje.
                    }
                    cb.onError(code, msg, null);
                }
            }
        });
    }

    /** Llamada RPC síncrona — debe ejecutarse desde un thread no-UI. */
    public static String callSync(String function, JSONObject body) throws Exception {
        okhttp3.OkHttpClient client = HttpClientManager.getInstance().getRawClient();
        okhttp3.Request request = HttpClientManager.getInstance()
                .buildPostRequest(BASE_RPC + function, body.toString());

        try (Response response = client.newCall(request).execute()) {
            String resBody = response.body() != null ? response.body().string() : "";
            if (!response.isSuccessful()) throw new Exception(resBody);
            return resBody;
        }
    }

    /** Devuelve el primer objeto del array JSON de respuesta, o null si está vacío. */
    public static JSONObject firstOrNull(String response) {
        try {
            JSONArray array = new JSONArray(response);
            return array.length() > 0 ? array.getJSONObject(0) : null;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Convierte el formato bytea de Postgres (\xHEX...) a Base64.
     * Permite que Flutter use base64Decode() directamente, sin lógica de DB en el frontend.
     */
    public static String byteaToBase64(String bytea) {
        if (bytea == null || bytea.isEmpty()) return null;
        try {
            String hex = bytea.startsWith("\\x") ? bytea.substring(2) : bytea;
            byte[] bytes = new byte[hex.length() / 2];
            for (int i = 0; i < bytes.length; i++) {
                bytes[i] = (byte) Integer.parseInt(hex.substring(i * 2, i * 2 + 2), 16);
            }
            return android.util.Base64.encodeToString(bytes, android.util.Base64.NO_WRAP);
        } catch (Exception e) {
            return null;
        }
    }
}
