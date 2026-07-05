package com.example.bocado.Channels;
import android.app.Activity;
import com.example.bocado.DAO.InteraccionDAO;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Managers.InteraccionManager;
import com.example.bocado.Managers.UsuarioManager;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;

public class InteractionsChannel {
    private static final String CHANNEL = "com.example.bocado/interacciones";
    private final Activity activity;
    private final UsuarioManager usuarioManager;
    private final InteraccionManager interaccionManager;

    public InteractionsChannel(Activity activity, BinaryMessenger messenger) {
        this.activity = activity;
        this.usuarioManager = new UsuarioManager(new UsuarioDAO());
        this.interaccionManager = new InteraccionManager(new InteraccionDAO());

        new MethodChannel(messenger, CHANNEL)
                .setMethodCallHandler(this::handleCall);
    }

    private void handleCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "updateSeguido" -> handleUpdateFollow(call, result);
            case "toggleInteraction" -> handleToggleInteraction(call, result);
            case "fetchMisInteracciones" -> handleFetchMisInteracciones(call, result);
            case "fetchComentarios" -> handleFetchComentarios(call, result);
            case "enviarComentario" -> handleEnviarComentario(call, result);
            default -> result.notImplemented();
        }
    }

    private void handleUpdateFollow(MethodCall call, MethodChannel.Result result) {
        int idSeguidor = call.argument("id_seguidor");
        int idSeguido = call.argument("id_seguido");
        Boolean siguiendo = call.argument("siguiendo");

        usuarioManager.updatefollow(idSeguidor, idSeguido, siguiendo, bridgeData(result));
    }

    private void handleToggleInteraction(MethodCall call, MethodChannel.Result result) {
        interaccionManager.toggleInteraccion(
                call.argument("id_usuario"),
                call.argument("id_receta"),
                call.argument("tipo"),
                call.argument("is_adding"),
                bridgeOk(result));
    }

    private void handleFetchMisInteracciones(MethodCall call, MethodChannel.Result result) {
        interaccionManager.fetchMisInteracciones(
                call.argument("id_usuario"),
                call.argument("id_receta"),
                bridgeData(result));
    }

    private void handleFetchComentarios(MethodCall call, MethodChannel.Result result) {
        interaccionManager.fetchComentarios(call.argument("recetaId"), bridgeData(result));
    }

    private void handleEnviarComentario(MethodCall call, MethodChannel.Result result) {
        interaccionManager.enviarComentario(
                call.argument("id_receta"),
                call.argument("id_usuario"),
                call.argument("comentario"),
                call.argument("id_comentario_padre"),
                bridgeOk(result));
    }

    private CallbackCB bridgeData(MethodChannel.Result result) {
        return new CallbackCB() {
            @Override
            public void onSuccess(String data) {
                activity.runOnUiThread(() -> result.success(data));
            }
            @Override
            public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        };
    }

    private CallbackCB bridgeOk(MethodChannel.Result result) {
        return new CallbackCB() {
            @Override
            public void onSuccess(String data) {
                activity.runOnUiThread(() -> result.success(true));
            }
            @Override
            public void onError(String code, String message, Object details) {
                activity.runOnUiThread(() -> result.error(code, message, details));
            }
        };
    }
}
