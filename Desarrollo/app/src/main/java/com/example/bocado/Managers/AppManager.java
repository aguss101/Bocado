package com.example.bocado.Managers;

import com.example.bocado.DAO.AppDAO;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;

import org.json.JSONObject;
public class AppManager {

    private final AppDAO appDAO;

    public AppManager(AppDAO appDAO) {
        this.appDAO = appDAO;
    }

    public void verificarActualizacion(int versionLocal, CallbackCB cb) {
        appDAO.obtenerVersionRemota(new CallbackCB() {
            @Override public void onSuccess(String body) {
                try {
                    JSONObject remoto = new JSONObject(body);
                    int versionRemota = remoto.optInt("versionCode", 0);
                    String versionName = remoto.optString("versionName", "");

                    JSONObject out = new JSONObject();
                    out.put("disponible", versionRemota > versionLocal);
                    out.put("versionName", versionName);
                    out.put("versionCode", versionRemota);
                    cb.onSuccess(out.toString());
                } catch (Exception e) {
                    cb.onError(ErrorCode.PARSE_ERROR, e.getMessage(), null);
                }
            }
            @Override public void onError(String code, String message, Object details) {
                cb.onError(code, message, details);
            }
        });
    }
}
