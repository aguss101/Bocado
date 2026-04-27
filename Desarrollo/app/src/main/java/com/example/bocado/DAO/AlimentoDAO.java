package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Managers.HttpClientManager;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AlimentoDAO {

    // ── Listar (para Flutter) ─────────────────────────────────────────────────
    // Sigue siendo síncrono porque RecetasChannel ya lo llama desde un Thread aparte
    public static List<Map<String, Object>> ListarParaFlutter() throws Exception {
        // Usamos execute() síncrono intencionalmente — el caller maneja el Thread
        okhttp3.OkHttpClient client = HttpClientManager.getInstance().getRawClient();

        okhttp3.Request request = HttpClientManager.getInstance()
                .buildGetRequest("/rest/v1/alimentos?select=*");

        try (Response response = client.newCall(request).execute()) {
            String body = response.body() != null ? response.body().string() : "[]";

            if (!response.isSuccessful()) {
                throw new Exception("Error al obtener alimentos: " + body);
            }

            JSONArray array = new JSONArray(body);
            List<Map<String, Object>> lista = new ArrayList<>();

            for (int i = 0; i < array.length(); i++) {
                JSONObject obj = array.getJSONObject(i);
                Map<String, Object> item = new HashMap<>();
                item.put("id",             obj.getInt("id"));
                item.put("nombre",         obj.getString("nombre"));
                item.put("proteinas",      obj.optDouble("proteinas", 0));
                item.put("carbohidratos",  obj.optDouble("carbohidratos", 0));
                item.put("grasas",         obj.optDouble("grasas", 0));
                lista.add(item);
            }

            return lista;
        }
    }

    // ── Crear simple (síncrono, llamado desde Thread en RecetasChannel) ────────
    public static int CrearSimple(String nombre, int idUsuario) throws Exception {
        JSONObject json = new JSONObject();
        json.put("nombre",     nombre);
        json.put("id_usuario", idUsuario);
        json.put("id_medida",  1);

        okhttp3.OkHttpClient client = HttpClientManager.getInstance().getRawClient();
        okhttp3.Request request = HttpClientManager.getInstance()
                .buildPostRequest("/rest/v1/alimentos", json.toString());

        try (Response response = client.newCall(request).execute()) {
            String responseBody = response.body() != null ? response.body().string() : "[]";

            if (!response.isSuccessful()) {
                throw new Exception("Error al crear alimento: " + responseBody);
            }

            JSONArray array = new JSONArray(responseBody);
            return array.length() > 0 ? array.getJSONObject(0).getInt("id") : -1;
        }
    }

    // ── Crear completo (asíncrono) ────────────────────────────────────────────
    public static void Crear(JSONObject alimentoJson, CallbackCB callbackCB) {
        HttpClientManager.getInstance().post(
                "/rest/v1/alimentos",
                alimentoJson.toString(),
                new Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        callbackCB.onError("NETWORK_ERROR", e.getMessage(), null);
                    }

                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        String responseBody = response.body() != null
                                ? response.body().string() : "[]";

                        if (response.isSuccessful()) {
                            callbackCB.onSuccess(responseBody);
                        } else {
                            callbackCB.onError("ERROR_CREATE", responseBody, null);
                        }
                    }
                }
        );
    }
}