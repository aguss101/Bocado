package com.example.bocado.DAO;

import com.example.bocado.Estaticos.Mapper;
import com.example.bocado.Managers.HttpClientManager;
import com.example.bocado.entidades.Usuario;
import org.json.JSONArray;
import org.json.JSONObject;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;
import java.io.IOException;

public class UsuarioDAO implements IUsuarioDAO {

    @Override
    public void registrar(Usuario u, LoginCallback cb) {
        try {
            JSONObject jsonBody = Mapper.usuarioToJson(u);

            HttpClientManager.getInstance().post("/rest/v1/usuarios", jsonBody.toString(), new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    cb.onError("NETWORK_ERROR", "Error de red: " + e.getMessage(), null);
                }

                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    String body = response.body() != null ? response.body().string() : "[]";
                    if (response.isSuccessful()) {
                        cb.onSuccess(body); // Devuelve el usuario creado
                    } else {
                        cb.onError("ERROR_API", "Fallo al registrar: " + body, null);
                    }
                }
            });
        } catch (Exception e) {
            cb.onError("ERROR_JSON", "Error armando datos: " + e.getMessage(), null);
        }
    }

    @Override
    public void login(String usuario, String contrasena, LoginCallback cb) {
        new Thread(() -> {
            String endpoint = "/rest/v1/usuarios?or=(usuario.eq." + usuario + ",correo.eq." + usuario + ")&contrasena=eq." + contrasena + "&activo=eq.true";
            HttpClientManager.getInstance().get(endpoint, new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    cb.onError("NETWORK_ERROR", "Error de red: " + e.getMessage(), null);
                }

                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    String body = response.body() != null ? response.body().string() : "[]";
                    if (response.isSuccessful()) {
                        try {
                            JSONArray array = new JSONArray(body);
                            if (array.length() > 0) {
                                cb.onSuccess(array.getJSONObject(0).toString()); // Login exitoso
                            } else {
                                cb.onError("CRED_INVALIDAS", "Usuario o contraseña incorrectos", null);
                            }
                        } catch (Exception e) {
                            cb.onError("ERROR_PARSE", "Error leyendo respuesta", null);
                        }
                    } else {
                        cb.onError("ERROR_API", "Fallo en el servidor: " + body, null);
                    }
                }
            });
        }).start();
    }

    @Override
    public void actualizar(int idUsuario, JSONObject actualizaciones, LoginCallback cb) {
        String endpoint = "/rest/v1/usuarios?id=eq." + idUsuario;

        HttpClientManager.getInstance().patch(endpoint, actualizaciones.toString(), new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                cb.onError("NETWORK_ERROR", "Error de red: " + e.getMessage(), null);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String body = response.body() != null ? response.body().string() : "[]";
                if (response.isSuccessful()) {
                    cb.onSuccess(body);
                } else {
                    cb.onError("ERROR_API", "Fallo al actualizar: " + body, null);
                }
            }
        });
    }
    @Override
    public void eliminar(int idUsuario, LoginCallback cb) {
        try {
            JSONObject jsonBody = new JSONObject();
            jsonBody.put("activo", false);
            String endpoint = "/rest/v1/usuarios?id=eq." + idUsuario;

            HttpClientManager.getInstance().patch(endpoint, jsonBody.toString(), new Callback() {
                @Override
                public void onFailure(Call call, IOException e) {
                    cb.onError("NETWORK_ERROR", "Error de red: " + e.getMessage(), null);
                }

                @Override
                public void onResponse(Call call, Response response) throws IOException {
                    if (response.isSuccessful()) {
                        cb.onSuccess("Usuario eliminado exitosamente");
                    } else {
                        cb.onError("ERROR_API", "Fallo al eliminar", null);
                    }
                }
            });
        } catch (Exception e) {
            cb.onError("ERROR_JSON", "Error eliminando al usuario: " + e.getMessage(), null);
        }
    }
}