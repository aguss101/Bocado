package com.example.bocado.DAO;

import okhttp3.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.net.URLEncoder;

public class UsuarioDAO2 {

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
}