package com.example.bocado.Channels;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import com.example.bocado.BuildConfig;
import com.example.bocado.DAO.AppDAO;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import com.example.bocado.Managers.AppManager;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class AppChannel {

    private static final String CHANNEL = "com.example.bocado/app";
    private static final String URL_DESCARGA = "https://links.bocado.tech/downloads/bocado.apk";

    private final Activity activity;
    private final AppManager appManager;

    public AppChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        this.appManager = new AppManager(new AppDAO());
        new MethodChannel(messenger, CHANNEL).setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "verificarActualizacion" -> handleVerificar(result);
            case "abrirDescarga"          -> handleAbrirDescarga(result);
            default -> result.notImplemented();
        }
    }

    private void handleVerificar(MethodChannel.Result result) {
        appManager.verificarActualizacion(BuildConfig.VERSION_CODE, new CallbackCB() {
            @Override public void onSuccess(String response) {
                activity.runOnUiThread(() -> result.success(response));
            }
            @Override public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        });
    }

    private void handleAbrirDescarga(MethodChannel.Result result) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(URL_DESCARGA));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            activity.startActivity(intent);
            result.success(null);
        } catch (Exception e) {
            result.error(ErrorCode.ERROR_INTERNO, e.getMessage(), null);
        }
    }
}
