package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.RpcCallHelper;
import org.json.JSONObject;

public class CuentaDAO {
    public void setPremiumStatus(int idUsuario, int idCuenta, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id_usuario", idUsuario);
            json.put("p_id_cuenta", idCuenta); // Enviamos el valor 1 o 2

            RpcCallHelper.callAsync("actualizar_id_cuenta", json, new CallbackCB() {
                @Override public void onSuccess(String response) {
                    cb.onSuccess("ok");
                }
                @Override public void onError(String code, String msg, Object data) {
                    cb.onError(code, msg, data);
                }
            });
        } catch (Exception e) {
            cb.onError("ERROR_JSON", e.getMessage(), null);
        }
    }
    public void validatePremiumCode(int idUsuario, String codigo, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id_usuario", idUsuario);
            json.put("p_codigo", codigo);

            RpcCallHelper.callAsync("validar_codigo_premium", json, cb);
        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error al procesar código: " + e.getMessage(), null);
        }
    }
}