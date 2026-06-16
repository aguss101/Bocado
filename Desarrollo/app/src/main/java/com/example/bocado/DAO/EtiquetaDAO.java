package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.RpcCallHelper;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.*;

public class EtiquetaDAO {

    private static List<Map<String, Object>> parseLista(String response) throws Exception {
        JSONArray array = new JSONArray(response);
        List<Map<String, Object>> lista = new ArrayList<>();

        for (int i = 0; i < array.length(); i++) {
            JSONObject obj = array.getJSONObject(i);
            Map<String, Object> item = new HashMap<>();
            // Mapeo según los campos del SP
            item.put("id", obj.getInt("id_etiqueta"));
            item.put("nombre", obj.getString("nombre"));
            item.put("id_usuario", obj.getInt("id_usuario"));
            lista.add(item);
        }

        return lista;
    }

    // Método para listar etiquetas pasando el ID del usuario como parámetro
    public static List<Map<String, Object>> listarMisEtiquetas(int idUsuario) throws Exception {
        JSONObject json = new JSONObject();
        json.put("p_id_usuario", idUsuario);

        // Llamada al SP "listar_mis_etiquetas"
        String response = RpcCallHelper.callSync("listar_mis_etiquetas", json);
        return parseLista(response);
    }

    // Opcional: Si necesitas crear etiquetas, adapta este método
    public static void crear(String nombre, int idUsuario, CallbackCB cb) throws Exception {
        JSONObject json = new JSONObject();
        json.put("p_nombre", nombre);
        json.put("p_id_usuario", idUsuario);

        RpcCallHelper.callAsync("crear_etiqueta", json, new CallbackCB() {
            @Override
            public void onSuccess(String response) {
                cb.onSuccess(response);
            }

            @Override
            public void onError(String code, String msg, Object data) {
                cb.onError(code, msg, data);
            }
        });
    }
}