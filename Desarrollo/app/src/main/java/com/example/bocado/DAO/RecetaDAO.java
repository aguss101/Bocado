package com.example.bocado.DAO;

import okhttp3.*;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.List;
import java.util.Map;

public class RecetaDAO {

    private static final String SUPABASE_URL = "https://sosbomunpwbgcezgfgzs.supabase.co";
    private static final String API_KEY = "TU_API_KEY";

    public static void Crear(Object rawArgs, LoginCallback callback) {

        new Thread(() -> {
            try {
                if (!(rawArgs instanceof Map)) {
                    callback.onError("ARGS_INVALIDOS", "Argumentos inválidos", null);
                    return;
                }

                Map<String, Object> args = (Map<String, Object>) rawArgs;

                String nombre        = (String) args.get("nombre");
                int idUsuario        = (int) args.get("id_usuario");
                int porciones        = (int) args.get("porciones");
                double caloriasTotal = (double) args.get("calorias_totales");
                String instrucciones = (String) args.get("instrucciones");

                List<Map<String, Object>> ingredientes =
                        (List<Map<String, Object>>) args.get("ingredientes");

                OkHttpClient client = new OkHttpClient();

                // 🔹 1. Insertar receta
                JSONObject recetaJson = new JSONObject();
                recetaJson.put("id_usuario", idUsuario);
                recetaJson.put("nombre", nombre);
                recetaJson.put("calorias_totales", caloriasTotal);
                recetaJson.put("porciones", porciones);
                recetaJson.put("instrucciones", instrucciones);
                recetaJson.put("visible", true);
                recetaJson.put("activo", true);

                RequestBody recetaBody = RequestBody.create(
                        recetaJson.toString(),
                        MediaType.parse("application/json; charset=utf-8")
                );

                Request recetaRequest = new Request.Builder()
                        .url(SUPABASE_URL + "/rest/v1/recetas")
                        .post(recetaBody)
                        .addHeader("apikey", API_KEY)
                        .addHeader("Authorization", "Bearer " + API_KEY)
                        .addHeader("Content-Type", "application/json")
                        .addHeader("Prefer", "return=representation")
                        .build();

                Response recetaResponse = client.newCall(recetaRequest).execute();

                String recetaRespBody = recetaResponse.body() != null
                        ? recetaResponse.body().string()
                        : "[]";

                if (!recetaResponse.isSuccessful()) {
                    callback.onError("ERROR_RECETA", recetaRespBody, null);
                    return;
                }

                JSONArray recetaArray = new JSONArray(recetaRespBody);
                int idReceta = recetaArray.getJSONObject(0).getInt("id");

                // 🔹 2. Insertar ingredientes
                for (Map<String, Object> ing : ingredientes) {

                    int idAlimento = (int) ing.get("id_alimento");
                    double cantidad = ((Number) ing.get("cantidad")).doubleValue();

                    JSONObject ingJson = new JSONObject();
                    ingJson.put("id_receta", idReceta);
                    ingJson.put("id_alimento", idAlimento);
                    ingJson.put("cantidad", cantidad);

                    RequestBody ingBody = RequestBody.create(
                            ingJson.toString(),
                            MediaType.parse("application/json; charset=utf-8")
                    );

                    Request ingRequest = new Request.Builder()
                            .url(SUPABASE_URL + "/rest/v1/recetas_alimentos")
                            .post(ingBody)
                            .addHeader("apikey", API_KEY)
                            .addHeader("Authorization", "Bearer " + API_KEY)
                            .addHeader("Content-Type", "application/json")
                            .build();

                    Response ingResponse = client.newCall(ingRequest).execute();

                    if (!ingResponse.isSuccessful()) {
                        callback.onError("ERROR_INGREDIENTE", "Fallo al insertar ingrediente", null);
                        return;
                    }
                }

                callback.onSuccess("RECETA_CREADA");

            } catch (Exception e) {
                e.printStackTrace();
                callback.onError("ERROR_GENERAL", e.getMessage(), null);
            }
        }).start();
    }
}