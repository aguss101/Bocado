package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import okhttp3.*;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class AlimentoDAO {

    private static final String SUPABASE_URL = "https://sosbomunpwbgcezgfgzs.supabase.co";
    private static final String API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvc2JvbXVucHdiZ2NlemdmZ3pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3MTY0MjQsImV4cCI6MjA4NzI5MjQyNH0._qPPTLykjx2sxlfutCG8Wwpjm5j7wf5P2TdKHE7y26w";

    // 🔹 LISTAR
    public static List<Map<String, Object>> ListarParaFlutter() throws Exception {

        OkHttpClient client = new OkHttpClient();

        String url = SUPABASE_URL + "/rest/v1/alimentos?select=*";

        Request request = new Request.Builder()
                .url(url)
                .get()
                .addHeader("apikey", API_KEY)
                .addHeader("Authorization", "Bearer " + API_KEY)
                .addHeader("Accept", "application/json")
                .build();

        Response response = client.newCall(request).execute();

        String body = response.body() != null ? response.body().string() : "[]";

        if (!response.isSuccessful()) {
            throw new Exception("Error al obtener alimentos: " + body);
        }

        JSONArray array = new JSONArray(body);
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

    // 🔹 CREAR SIMPLE
    public static int CrearSimple(String nombre, int idUsuario) throws Exception {

        OkHttpClient client = new OkHttpClient();

        JSONObject json = new JSONObject();
        json.put("nombre", nombre);
        json.put("id_usuario", idUsuario);
        json.put("id_medida", 1);

        RequestBody body = RequestBody.create(
                json.toString(),
                MediaType.parse("application/json; charset=utf-8")
        );

        Request request = new Request.Builder()
                .url(SUPABASE_URL + "/rest/v1/alimentos")
                .post(body)
                .addHeader("apikey", API_KEY)
                .addHeader("Authorization", "Bearer " + API_KEY)
                .addHeader("Content-Type", "application/json")
                .addHeader("Prefer", "return=representation")
                .build();

        Response response = client.newCall(request).execute();

        String responseBody = response.body() != null ? response.body().string() : "[]";

        if (!response.isSuccessful()) {
            throw new Exception("Error al crear alimento: " + responseBody);
        }

        JSONArray array = new JSONArray(responseBody);

        if (array.length() > 0) {
            return array.getJSONObject(0).getInt("id");
        }

        return -1;
    }

    // 🔹 CREAR COMPLETO
    public static void Crear(JSONObject alimentoJson, CallbackCB callbackCB) {

        new Thread(() -> {
            try {
                OkHttpClient client = new OkHttpClient();

                RequestBody body = RequestBody.create(
                        alimentoJson.toString(),
                        MediaType.parse("application/json; charset=utf-8")
                );

                Request request = new Request.Builder()
                        .url(SUPABASE_URL + "/rest/v1/alimentos")
                        .post(body)
                        .addHeader("apikey", API_KEY)
                        .addHeader("Authorization", "Bearer " + API_KEY)
                        .addHeader("Content-Type", "application/json")
                        .addHeader("Prefer", "return=representation")
                        .build();

                Response response = client.newCall(request).execute();

                String responseBody = response.body() != null ? response.body().string() : "[]";

                if (response.isSuccessful()) {
                    callbackCB.onSuccess(responseBody);
                } else {
                    callbackCB.onError("ERROR_CREATE", responseBody, null);
                }

            } catch (Exception e) {
                e.printStackTrace();
                callbackCB.onError("NETWORK_ERROR", e.getMessage(), null);
            }
        }).start();
    }
}