package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.IUsuario;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Estaticos.Mapper;
import com.example.bocado.Estaticos.RpcCallHelper;
import com.example.bocado.entidades.Usuario;

import org.json.JSONObject;

public class UsuarioDAO implements IUsuario {

    @Override
    public void loginOrCreateGoogle(String email, String googleId, String nombre, String apellido, String foto, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_correo", email);
            json.put("p_nombre", nombre);
            json.put("p_apellido", apellido);
            json.put("p_foto", foto);
            json.put("p_google_id", googleId);

            RpcCallHelper.callAsync("login_or_create_google", json,
                    primeraFilaOError(cb, ErrorCode.ERROR_REGISTRO, "No se pudo autenticar con Google en la base de datos."));

        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error al empaquetar los datos de Google: " + e.getMessage(), null);
        }
    }
    @Override
    public void registrar(Usuario u, CallbackCB cb) {
        try {
            JSONObject data = Mapper.usuarioToJson(u);
            JSONObject json = new JSONObject();
            json.put("p_data", data);

            RpcCallHelper.callAsync("registrar_usuario", json,
                    primeraFilaOError(cb, ErrorCode.ERROR_REGISTRO, "No se pudo crear el usuario"));

        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error armando datos: " + e.getMessage(), null);
        }
    }

    @Override
    public void login(String usuario, String contrasena, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_usuario", usuario);
            json.put("p_contrasena", contrasena);

            RpcCallHelper.callAsync("login_usuario", json,
                    primeraFilaOError(cb, ErrorCode.CRED_INVALIDAS, "Usuario o contraseña incorrectos"));

        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_INTERNO, e.getMessage(), null);
        }
    }

    @Override
    public void actualizar(int idUsuario, JSONObject actualizaciones, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id", idUsuario);
            json.put("p_data", actualizaciones);

            RpcCallHelper.callAsync("actualizar_usuario_json", json, cb);

        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_INTERNO, e.getMessage(), null);
        }
    }

    @Override
    public void eliminar(int idUsuario, CallbackCB cb) {
        try {
            JSONObject json = new JSONObject();
            json.put("p_id", idUsuario);

            RpcCallHelper.callAsync("eliminar_usuario", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    if (Boolean.parseBoolean(response)) {
                        cb.onSuccess("Usuario eliminado exitosamente");
                    } else {
                        cb.onError(ErrorCode.NOT_FOUND, "El usuario no existe", null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    cb.onError(code, msg, data);
                }
            });

        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error eliminando al usuario: " + e.getMessage(), null);
        }
    }

    private CallbackCB primeraFilaOError(CallbackCB cb, String errorCode, String errorMsg) {
        return new CallbackCB() {
            @Override
            public void onSuccess(String response) {
                JSONObject obj = RpcCallHelper.firstOrNull(response);
                if (obj == null) {
                    cb.onError(errorCode, errorMsg, null);
                    return;
                }
                cb.onSuccess(obj.toString());
            }

            @Override
            public void onError(String code, String msg, Object data) {
                cb.onError(code, msg, data);
            }
        };
    }
}
