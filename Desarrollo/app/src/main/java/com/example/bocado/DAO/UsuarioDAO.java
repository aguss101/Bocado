package com.example.bocado.DAO;

import okhttp3.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.net.URLEncoder;

public class UsuarioDAO {

    private static final String SUPABASE_URL = "https://sosbomunpwbgcezgfgzs.supabase.co";
    private static final String API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvc2JvbXVucHdiZ2NlemdmZ3pzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3MTY0MjQsImV4cCI6MjA4NzI5MjQyNH0._qPPTLykjx2sxlfutCG8Wwpjm5j7wf5P2TdKHE7y26w";

    public static void login(String usuario, String password, LoginCallback callback) {

        new Thread(() -> {
            try {
                OkHttpClient client = new OkHttpClient();

                String usuarioClean = usuario.trim();
                String passwordClean = password.trim();

                String usuarioEncoded = URLEncoder.encode(usuarioClean, "UTF-8");
                String passwordEncoded = URLEncoder.encode(passwordClean, "UTF-8");

                String url = SUPABASE_URL +
                        "/rest/v1/usuarios" +
                        "?usuario=eq." + usuarioEncoded +
                        "&contrasena=eq." + passwordEncoded;

                android.util.Log.d("LOGIN_DEBUG", "URL: " + url);
                android.util.Log.d("LOGIN_DEBUG", "USUARIO: " + usuarioClean);
                android.util.Log.d("LOGIN_DEBUG", "PASSWORD: " + passwordClean);

                Request request = new Request.Builder()
                        .url(url)
                        .get()
                        .addHeader("apikey", API_KEY)
                        .addHeader("Authorization", "Bearer " + API_KEY)
                        .addHeader("Content-Type", "application/json")
                        .addHeader("Accept", "application/json")
                        .build();

                Response response = client.newCall(request).execute();
                android.util.Log.d("LOGIN_DEBUG", "CODE: " + response.code());

                String body = response.body() != null ? response.body().string() : "[]";

                System.out.println("RESPONSE CODE: " + response.code());
                android.util.Log.d("LOGIN_DEBUG", "BODY: " + body);

                JSONArray array = new JSONArray(body);

                if (array.length() > 0) {
                    JSONObject user = array.getJSONObject(0);
                    callback.onSuccess(user.toString());
                } else {
                    callback.onError("CREDENCIALES_INVALIDAS", "Usuario o contraseña incorrectos", null);
                }

            } catch (Exception e) {
                e.printStackTrace();
                android.util.Log.e("LOGIN_ERROR", e.toString());
                callback.onError("NETWORK_ERROR", e.getMessage(), null);
            }
        }).start();
    }
    public static void register(Integer idNacion, Integer idGenero, String nombre, String apellido, String correo, String usuario, String contrasena, String fechaNacimiento, LoginCallback callback){
        new Thread(() -> {
            try{
                OkHttpClient client = new OkHttpClient();
                String url = SUPABASE_URL + "/rest/v1/usuarios";

                String nombreClean = nombre.trim();
                String apellidoClean = apellido.trim();
                String correoClean = correo.trim();
                String usuarioClean = usuario.trim();
                String contrasenaClean = contrasena.trim();

                android.util.Log.d("REGISTER_DEBUG", "URL" + url);
                android.util.Log.d("REGISTER_DEBUG", "URL" + usuarioClean);

                JSONObject jsonBody = new JSONObject();
                jsonBody.put("id_nacion", idNacion);
                jsonBody.put("id_genero", idGenero);
                jsonBody.put("nombre", nombreClean);
                jsonBody.put("apellido", apellidoClean);
                jsonBody.put("correo", correoClean);
                jsonBody.put("usuario", usuarioClean);
                jsonBody.put("contrasena", contrasenaClean);
                jsonBody.put("fecha_nacimiento",fechaNacimiento);

                RequestBody body = RequestBody.create(jsonBody.toString(),okhttp3.MediaType.parse("application/json; charset=utf-8"));

                Request request = new Request.Builder()
                        .url(url)
                        .post(body)
                        .addHeader("apikey", API_KEY)
                        .addHeader("Authorization", "Bearer " + API_KEY)
                        .addHeader("Content-Type", "application/json")
                        .addHeader("Accept", "application/json")
                        .addHeader("Prefer", "return=representation")
                        .build();

                Response response = client.newCall(request).execute();
                android.util.Log.d("REGISTER_DEBUG", "CODE: " + response.code());

                String responseBody = response.body() != null ? response.body().string() : "[]";
                android.util.Log.d("REGISTER_DEBUG", "BODY: " + responseBody);

                if(response.isSuccessful()){
                    JSONArray array = new JSONArray(responseBody);

                    if(array.length() > 0){
                        JSONObject newUser = array.getJSONObject(0);
                        callback.onSuccess(newUser.toString());
                    } else {
                        callback.onError("REGISTRO_VACIO", "Se creó pero no devolvio datos",  null);
                    }
                } else {
                    callback.onError("ERROR_REGISTRO", "Fallo al crear el usuario: " + responseBody, null);
                }
            } catch(Exception e){
                e.printStackTrace();
                android.util.Log.e("REGISTER_ERROR", e.toString());
                callback.onError("NETWORK_ERROR", e.getMessage(), null);
            }
        }).start();
    }

    /// Habria que moverlo a otro lado porque no creo que corresponda estrictamente a Usuarios.
    public static void trearTabla (String tabla, LoginCallback callback){
        new Thread(()-> {
                try{
                    OkHttpClient client = new OkHttpClient();

                    String url = SUPABASE_URL + "/rest/v1/" + tabla + "?select=*";

                    Request request = new Request.Builder()
                            .url(url)
                            .get()
                            .addHeader("apikey", API_KEY)
                            .addHeader("Authorization", "Bearer" + API_KEY)
                            .addHeader("Accept", "application/json")
                            .build();

                    Response response = client.newCall(request).execute();
                    String responseBody = response.body() != null ? response.body().string() : "[]";

                    if(response.isSuccessful()){
                        callback.onSuccess(responseBody);
                    } else{
                        callback.onError("ERROR_GET", "Fallo al traer" + tabla, null);
                    }
                }catch (Exception e){
                    callback.onError("NETWORK_ERROR", e.getMessage(), null);
                }
            }
        ).start();
    }
}