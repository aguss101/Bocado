package com.example.bocado.Channels;

import android.app.Activity;
import com.example.bocado.DAO.CuentaDAO;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class AccountChannel {

    private static final String CHANNEL = "com.example.bocado/account";
    private final Activity activity;
    private final CuentaDAO cuentaDAO;

    public AccountChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        this.cuentaDAO = new CuentaDAO();

        new MethodChannel(messenger, CHANNEL)
                .setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        if ("actualizarEstadoPremium".equals(call.method)) {
            handleActualizarPremium(call, result);
        } else {
            result.notImplemented();
        }
    }

    private void handleActualizarPremium(MethodCall call, MethodChannel.Result result) {
        Integer idUsuario = call.argument("id_usuario");
        Integer idCuenta = call.argument("id_cuenta");

        android.util.Log.d("DEBUG_BOCADO", "Iniciando actualización en DAO para usuario: " + idUsuario + " cuenta: " + idCuenta);

        cuentaDAO.setPremiumStatus(idUsuario, idCuenta, new CallbackCB() {
            @Override
            public void onSuccess(String data) {
                android.util.Log.d("DEBUG_BOCADO", "ÉXITO en DAO: " + data);
                activity.runOnUiThread(() -> result.success(true));
            }
            @Override
            public void onError(String code, String msg, Object details) {
                android.util.Log.e("DEBUG_BOCADO", "ERROR en DAO: " + code + " - " + msg);
                activity.runOnUiThread(() -> result.error(code, msg, details));
            }
        });
    }
}