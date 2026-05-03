package com.example.bocado.DAO;

import android.util.Log;
import com.example.bocado.DAO.Interfaces.IUsuario;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.entidades.Usuario;

import org.json.JSONArray;
import org.json.JSONObject;

import okhttp3.Call;
import okhttp3.Response;

import java.io.IOException;

public class UsuarioDAO implements IUsuario {

    private static final String BASE_RPC = "/rest/v1/rpc/";
    private void callRpc(String rpc, JSONObject body, CallbackCB cb) {
        new Thread(() -> {
            try {
                String endpoint = BASE_RPC + rpc;

                HttpClientManager.getInstance().post(endpoint, body.toString(), new okhttp3.Callback() {

                    @Override
                    public void onFailure(Call call, IOException e) {
                        cb.onError("NETWORK_ERROR", "Error de red: " + e.getMessage(), null);
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
                });

            } catch (Exception e) {
                cb.onError("ERROR_INTERNO", e.getMessage(), null);
            }
        }).start();
    }
    private JSONObject firstOrNull(String response) {
        try {
            JSONArray array = new JSONArray(response);
            return array.length() > 0 ? array.getJSONObject(0) : null;
        } catch (Exception e) {
            return null;
        }
    }
    @Override
    public void registrar(Usuario u, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_usuario", u.getUsuario());
            json.put("p_correo", u.getCorreo());
            json.put("p_contrasena", u.getContrasena());

            callRpc("registrar_usuario", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    JSONObject obj = firstOrNull(response);

                    if (obj != null) {
                        cb.onSuccess(obj.toString());
                    } else {
                        cb.onError("ERROR_REGISTRO", "No se pudo crear el usuario", null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    cb.onError(code, msg, data);
                }
            });

        } catch (Exception e) {
            cb.onError("ERROR_JSON", "Error armando datos: " + e.getMessage(), null);
        }
    }
    @Override
    public void login(String usuario, String contrasena, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_usuario", usuario);
            json.put("p_contrasena", contrasena);

            Log.d("DEV_TEST", "Ingreso a la funcion");

            callRpc("login_usuario", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    JSONObject obj = firstOrNull(response);

                    if (obj != null) {
                        cb.onSuccess(obj.toString());
                    } else {
                        cb.onError("CRED_INVALIDAS", "Usuario o contraseña incorrectos", null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    cb.onError(code, msg, data);
                    Log.d("DEV_TEST", msg);
                }
            });

        } catch (Exception e) {
            cb.onError("ERROR_INTERNO", e.getMessage(), null);
        }
    }
    @Override
    public void actualizar(int idUsuario, JSONObject actualizaciones, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id", idUsuario);
            json.put("p_data", actualizaciones);

            callRpc("actualizar_usuario_json", json, cb);

        } catch (Exception e) {
            cb.onError("ERROR_INTERNO", e.getMessage(), null);
        }
    }
    @Override
    public void eliminar(int idUsuario, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id", idUsuario);

            callRpc("eliminar_usuario", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    boolean eliminado = Boolean.parseBoolean(response);

                    if (eliminado) {
                        cb.onSuccess("Usuario eliminado exitosamente");
                    } else {
                        cb.onError("NOT_FOUND", "El usuario no existe", null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    cb.onError(code, msg, data);
                }
            });

        } catch (Exception e) {
            cb.onError("ERROR_JSON", "Error eliminando al usuario: " + e.getMessage(), null);
        }
    }
}