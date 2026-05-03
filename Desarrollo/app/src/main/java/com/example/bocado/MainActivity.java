package com.example.bocado;

import com.example.bocado.DAO.AlimentoDAO;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.RecetaDAO;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Managers.RecetaManager;
import com.example.bocado.entidades.Usuario;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;
import com.example.bocado.Managers.UsuarioManager;
import com.example.bocado.Managers.HttpClientManager;
import okhttp3.Call;
import okhttp3.Response;
import java.io.IOException;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import android.os.Bundle;
import androidx.core.splashscreen.SplashScreen;

public class MainActivity extends FlutterActivity {


    private static final String CHANNEL_ACCESS = "com.example.bocado/access";
    private static final String CHANNEL_RECETAS = "com.example.bocado/recetas";
    private final UsuarioManager usuarioManager = new UsuarioManager(new UsuarioDAO());
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
    }
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_ACCESS)
                .setMethodCallHandler((call, result) -> {

                    switch (call.method){
                        case "loginJava":
                            String usuario = call.argument("usuario");
                            String contrasena = call.argument("contrasena");

                            usuarioManager.login(usuario, contrasena, new CallbackCB() {
                                @Override
                                public void onSuccess(String response) {
                                    runOnUiThread(() -> result.success(response));
                                }
                                @Override
                                public void onError(String code, String message, Object details) {
                                    runOnUiThread(() -> result.error(code, message, details));
                                }
                            });
                            break;

                        case "register":
                            Usuario nuevoU = new Usuario();
                            nuevoU.setNombre(call.argument("nombre"));
                            nuevoU.setApellido(call.argument("apellido"));
                            nuevoU.setCorreo(call.argument("email"));
                            nuevoU.setUsuario(call.argument("usuario"));
                            nuevoU.setContrasena(call.argument("password"));
                            nuevoU.setNacion(String.valueOf(call.argument("nacion")));
                            nuevoU.setGenero(String.valueOf(call.argument("genero")));
                            nuevoU.setFecha_Nacimiento(call.argument("fechaNacimiento"));

                            usuarioManager.registrar(nuevoU, new CallbackCB() {
                                @Override
                                public void onSuccess(String responseData) {
                                    runOnUiThread(() -> result.success(responseData));
                                }

                                @Override
                                public void onError(String code, String message, Object details) {
                                    runOnUiThread(() -> result.error(code, message, details));
                                }
                            });
                            break;

                        case "getNaciones":
                            HttpClientManager.getInstance().get("/rest/v1/naciones?select=*", new okhttp3.Callback() {
                                @Override
                                public void onFailure(Call call1, IOException e) {
                                    runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                                }

                                @Override
                                public void onResponse(Call call1, Response response) throws IOException {
                                    String body = response.body() != null ? response.body().string() : "[]";
                                    runOnUiThread(() -> result.success(body));
                                }
                            });
                            break;

                        case "getGeneros":
                            HttpClientManager.getInstance().get("/rest/v1/generos?select=*", new okhttp3.Callback() {
                                @Override
                                public void onFailure(Call call1, IOException e) {
                                    runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                                }

                                @Override
                                public void onResponse(Call call1, Response response) throws IOException {
                                    String body = response.body() != null ? response.body().string() : "[]";
                                    runOnUiThread(() -> result.success(body));
                                }
                            });
                            break;

                        default:
                            result.notImplemented();
                            break;
                    }
                });

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_RECETAS)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "getRecetasUsuario":
                            Integer usuarioId = call.argument("usuarioId");
                            HttpClientManager.getInstance().get(
                                    "/rest/v1/vistas_recetas_macros?select=*&id_usuario=eq." + usuarioId,
                                    new okhttp3.Callback() {
                                        @Override
                                        public void onFailure(Call call1, IOException e) {
                                            runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                                        }
                                        @Override
                                        public void onResponse(Call call1, Response response) throws IOException {
                                            String body = response.body() != null ? response.body().string() : "[]";
                                            runOnUiThread(() -> result.success(body));
                                        }
                                    }
                            );
                            break;
                        // ── getAlimentos ─────────────────────────────────────
                        case "getAlimentos":
                            new Thread(() -> {
                                try {
                                    java.util.List<Map<String, Object>> lista = AlimentoDAO.ListarParaFlutter();
                                    runOnUiThread(() -> result.success(lista));
                                } catch (SQLException e) {
                                    runOnUiThread(() -> result.error("DB_ERROR", e.getMessage(), null));
                                } catch (Exception e) {
                                    throw new RuntimeException(e);
                                }
                            }).start();
                            break;

                        // ── addAlimento ──────────────────────────────────────
                        case "addAlimento":
                            String nombre    = call.argument("nombre");
                            Integer idUsuario = call.argument("id_usuario");
                            new Thread(() -> {
                                try {
                                    int nuevoId = AlimentoDAO.CrearSimple(nombre, idUsuario);
                                    Map<String, Object> res = new HashMap<>();
                                    res.put("id", nuevoId);
                                    runOnUiThread(() -> result.success(res));
                                } catch (SQLException e) {
                                    runOnUiThread(() -> result.error("DB_ERROR", e.getMessage(), null));
                                } catch (Exception e) {
                                    throw new RuntimeException(e);
                                }
                            }).start();
                            break;

                        // ── saveReceta ───────────────────────────────────────
                        case "saveReceta":
                            Map<String, Object> args = call.arguments();
                                    RecetaManager.getInstance().crear(args, new MethodChannel.Result() {
                                        @Override
                                        public void success(Object data) { runOnUiThread(() -> result.success(data)); }

                                        @Override
                                        public void error( String code, String message, Object details) { runOnUiThread(() -> result.error(code, message, details)); }

                                        @Override
                                        public void notImplemented() { runOnUiThread(() -> result.notImplemented()); }
                                    });
                            break;
                        case "getRecetas":
                            HttpClientManager.getInstance().get("/rest/v1/vistas_recetas_macros?select=*", new okhttp3.Callback() {
                                @Override
                                public void onFailure(Call call1, IOException e) {
                                    runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                                }

                                @Override
                                public void onResponse(Call call1, Response response) throws IOException {
                                    String body = response.body() != null ? response.body().string() : "[]";
                                    runOnUiThread(() -> result.success(body));
                                }
                            });
                            break;
                        case "getRecetaDetalle":
                            HttpClientManager.getInstance().get("/rest/v1/recetas?select=*,usuarios!UR(nombre,foto),recetas_alimentos(cantidad,alimentos(nombre))&id=eq." + call.argument("id"), new okhttp3.Callback(){
                                public void onFailure(Call call1, IOException e) {
                                    runOnUiThread(() -> result.error("NETWORK_ERROR", e.getMessage(), null));
                                }

                                @Override
                                public void onResponse(Call call1, Response response) throws IOException {
                                    if(response.isSuccessful()){
                                        String body = response.body() != null ? response.body().string() : "[]";
                                        runOnUiThread(() -> result.success(body));
                                    }else {
                                        String detalleError = response.body() != null ? response.body().string() : "Sin detalles";

                                        final String errorMsg = "Fallo Supabase 300. Detalle: " + detalleError;
                                        runOnUiThread(() -> result.error("API_ERROR", errorMsg, null));
                                    }
                                }
                            });
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }

}