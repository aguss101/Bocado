package com.example.bocado.Managers;

import com.example.bocado.BuildConfig;
import okhttp3.*;
import java.io.IOException;

public class HttpClientManager {

    private static HttpClientManager instance;
    private final OkHttpClient client;
    private final String supaUrl = BuildConfig.SUPABASE_URL;
    private final String supaKey = BuildConfig.SUPABASE_KEY;

    private HttpClientManager() {
        this.client = new OkHttpClient();
    }

    public static HttpClientManager getInstance() {
        if (instance == null) {
            instance = new HttpClientManager();
        }
        return instance;
    }

    private Request.Builder getBaseBuilder(String endpoint) {
        return new Request.Builder()
                .url(supaUrl + endpoint)
                .addHeader("apikey", supaKey)
                .addHeader("Authorization", "Bearer " + supaKey)
                .addHeader("Content-Type", "application/json")
                .addHeader("Accept", "application/json")
                .addHeader("Prefer", "return=representation");
    }

    public void get(String endpoint, Callback callback) {
        Request request = getBaseBuilder(endpoint).get().build();
        client.newCall(request).enqueue(callback);
    }

    public void post(String endpoint, String jsonBody, Callback callback) {
        RequestBody body = RequestBody.create(jsonBody, MediaType.parse("application/json; charset=utf-8"));
        Request request = getBaseBuilder(endpoint).post(body).build();
        client.newCall(request).enqueue(callback);
    }

    public void patch(String endpoint, String jsonBody, Callback callback) {
        RequestBody body = RequestBody.create(jsonBody, MediaType.parse("application/json; charset=utf-8"));
        Request request = getBaseBuilder(endpoint).patch(body).build();
        client.newCall(request).enqueue(callback);
    }

    public void delete(String endpoint, Callback callback) {
        Request request = getBaseBuilder(endpoint).delete().build();
        client.newCall(request).enqueue(callback);
    }
}