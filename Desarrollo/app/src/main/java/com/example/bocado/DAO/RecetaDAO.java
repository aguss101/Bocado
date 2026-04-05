package com.example.bocado.DAO;

import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.DAO.Interfaces.CallbackCB;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.util.List;
import java.util.Map;

public class RecetaDAO {

    public void crear(Map<String, Object> args, CallbackCB callback) {
        try {
            String nombre = (String) args.get("nombre");
            int idUsuario = (int) args.get("id_usuario");
            int porciones = (int) args.get("porciones");
            double caloriasTotal = ((Number) args.get("calorias_totales")).doubleValue();
            String instrucciones = (String) args.get("instrucciones");

            List<Map<String, Object>> ingredientes = (List<Map<String, Object>>) args.get("ingredientes");

            JSONObject recetaJson = new JSONObject();
            recetaJson.put("id_usuario", idUsuario);
            recetaJson.put("nombre", nombre);
            recetaJson.put("calorias_totales", caloriasTotal);
            recetaJson.put("porciones", porciones);
            recetaJson.put("instrucciones", instrucciones);
            recetaJson.put("visibilidad", true);
            recetaJson.put("activo", true);
            recetaJson.put("precio", args.containsKey("precio") ? ((Number) args.get("precio")).doubleValue() : 0.0);

            HttpClientManager.getInstance().post("/rest/v1/recetas", recetaJson.toString(), new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    callback.onError("NETWORK_ERROR", "Fallo de red al crear receta: " + e.getMessage(), null);
                }

                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    String responseBody = response.body() != null ? response.body().string() : "[]";

                    if (!response.isSuccessful()) {
                        callback.onError("ERROR_RECETA", responseBody, null);
                        return;
                    }

                    try {
                        JSONArray recetaArray = new JSONArray(responseBody);
                        int idReceta = recetaArray.getJSONObject(0).getInt("id");

                        if (ingredientes == null || ingredientes.isEmpty()) {
                            callback.onSuccess(recetaArray.toString());
                            return;
                        }

                        JSONArray ingredientesArray = new JSONArray();

                        for (Map<String, Object> ing : ingredientes) {
                            JSONObject ingJson = new JSONObject();
                            double precioIngrediente = ing.containsKey("precio") ? ((Number) ing.get("precio")).doubleValue() : 0.0;

                            ingJson.put("id_receta", idReceta);
                            ingJson.put("id_alimento", (int) ing.get("id_alimento"));
                            ingJson.put("cantidad", ((Number) ing.get("cantidad")).doubleValue());
                            ingJson.put("precio", precioIngrediente);

                            ingredientesArray.put(ingJson);
                        }

                        HttpClientManager.getInstance().post("/rest/v1/recetas_alimentos", ingredientesArray.toString(), new Callback() {
                            @Override
                            public void onFailure(Call call, IOException e) {
                                callback.onError("NETWORK_ERROR_ING", "Receta creada, pero falló la red en los ingredientes.", null);
                            }

                            @Override
                            public void onResponse(Call call, Response responseIng) throws IOException {
                                String ingBody = responseIng.body() != null ? responseIng.body().string() : "";

                                if (!responseIng.isSuccessful()) {
                                    callback.onError("ERROR_INGREDIENTES", "Receta creada, pero error al enlazar ingredientes: " + ingBody, null);
                                    return;
                                }
                                callback.onSuccess(recetaArray.toString());
                            }
                        });

                    } catch (Exception e) {
                        callback.onError("PARSE_ERROR", "Error al leer respuesta de Supabase: " + e.getMessage(), null);
                    }
                }
            });

        } catch (Exception e) {
            callback.onError("ERROR_CRITICO", e.getMessage(), null);
        }
    }
}