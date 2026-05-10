package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.RpcCallHelper;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.*;

public class AlimentoDAO {

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

    public static List<Map<String, Object>> ListarParaFlutter() throws Exception {
        String response = RpcCallHelper.callSync("listar_alimentos", new JSONObject());
        return parseLista(response);
    }

    public static int CrearSimple(String nombre, int idUsuario) throws Exception {
        JSONObject json = new JSONObject();
        json.put("p_nombre", nombre);
        json.put("p_id_usuario", idUsuario);

        String response = RpcCallHelper.callSync("crear_alimento_simple", json);
        return Integer.parseInt(response);
    }

    public static void Crear(JSONObject alimentoJson, CallbackCB cb) throws Exception {
        JSONObject json = new JSONObject();
        json.put("p_data", alimentoJson);

        RpcCallHelper.callAsync("crear_alimento", json, new CallbackCB() {
            @Override
            public void onSuccess(String response) {
                try {
                    JSONObject obj = RpcCallHelper.firstOrNull(response);
                    if (obj != null) {
                        cb.onSuccess(obj.toString());
                    } else {
                        cb.onError(ErrorCode.ERROR_CREATE, "No se pudo crear", null);
                    }
                } catch (Exception e) {
                    cb.onError(ErrorCode.PARSE_ERROR, e.getMessage(), null);
                }
            }

            @Override
            public void onError(String code, String msg, Object data) {
                cb.onError(code, msg, data);
            }
        });
    }
}
