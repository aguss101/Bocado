package com.example.bocado.DAO;

import android.util.Log;
import com.example.bocado.DAO.Interfaces.IUsuario;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
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

            RpcCallHelper.callAsync("login_or_create_google", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    JSONObject obj = RpcCallHelper.firstOrNull(response);

                    if (obj == null) {
                        cb.onError(ErrorCode.ERROR_REGISTRO, "No se pudo autenticar con Google en la base de datos.", null);
                        return;
                    }
                    // foto/banner ya son URLs de Storage (text) → se pasan tal cual.
                    cb.onSuccess(obj.toString());
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    cb.onError(code, msg, data);
                }
            });

        } catch (Exception e) {
            cb.onError(ErrorCode.ERROR_JSON, "Error al empaquetar los datos de Google: " + e.getMessage(), null);
        }
    }
    @Override
    public void registrar(Usuario u, CallbackCB cb) {
        try {
            // La función registrar_usuario(p_data jsonb) espera TODOS los campos.
            JSONObject data = new JSONObject();
            data.put("usuario", u.getUsuario());
            data.put("correo", u.getCorreo());
            data.put("contrasena", u.getContrasena());
            data.put("nombre", u.getNombre());
            data.put("apellido", u.getApellido());
            data.put("id_nacion", Integer.parseInt(u.getNacion()));
            data.put("id_genero", Integer.parseInt(u.getGenero()));
            data.put("fecha_nacimiento", u.getFechaNacimientoIso());

            JSONObject json = new JSONObject();
            json.put("p_data", data);

            RpcCallHelper.callAsync("registrar_usuario", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    JSONObject obj = RpcCallHelper.firstOrNull(response);
                    if (obj != null) {
                        cb.onSuccess(obj.toString());
                    } else {
                        cb.onError(ErrorCode.ERROR_REGISTRO, "No se pudo crear el usuario", null);
                    }
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    cb.onError(code, msg, data);
                }
            });

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

            Log.d("DEV_TEST", "Ingreso a la funcion");

            RpcCallHelper.callAsync("login_usuario", json, new CallbackCB() {
                @Override
                public void onSuccess(String response) {
                    JSONObject obj = RpcCallHelper.firstOrNull(response);
                    if (obj == null) {
                        cb.onError(ErrorCode.CRED_INVALIDAS, "Usuario o contraseña incorrectos", null);
                        return;
                    }
                    // foto/banner ya son URLs de Storage (text) → se pasan tal cual.
                    cb.onSuccess(obj.toString());
                }

                @Override
                public void onError(String code, String msg, Object data) {
                    Log.d("DEV_TEST", msg);
                    cb.onError(code, msg, data);
                }
            });

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
}
