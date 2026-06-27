package com.example.bocado.DAO;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Managers.HttpClientManager;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Request;
import okhttp3.Response;

import java.io.IOException;

/**
 * Acceso al version.json publicado por el CI en GitHub Pages.
 * No es Supabase: por eso usa el cliente OkHttp crudo (getRawClient) en vez de
 * HttpClientManager.get(), que inyecta la URL base y los headers de Supabase.
 */
public class AppDAO {

    private static final String URL_VERSION = "https://links.bocado.tech/version.json";

    public void obtenerVersionRemota(CallbackCB cb) {
        Request request = new Request.Builder().url(URL_VERSION).get().build();
        HttpClientManager.getInstance().getRawClient().newCall(request).enqueue(new Callback() {
            @Override public void onFailure(Call call, IOException e) {
                cb.onError(ErrorCode.NETWORK_ERROR, e.getMessage(), null);
            }
            @Override public void onResponse(Call call, Response response) throws IOException {
                String body = response.body() != null ? response.body().string() : "{}";
                cb.onSuccess(body);
            }
        });
    }
}
