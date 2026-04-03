package com.example.bocado;

import com.example.bocado.DAO.AlimentoDAO;
import com.example.bocado.DAO.LoginCallback;
import com.example.bocado.DAO.RecetaDAO;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.entidades.Usuario;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import androidx.annotation.NonNull;
import com.example.bocado.Managers.UsuarioManager;
import com.example.bocado.Managers.HttpClientManager;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;
import java.io.IOException;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;


public class MainActivity extends FlutterActivity {

    private static final String CHANNEL_ACCESS = "com.example.bocado/access";
    private static final String CHANNEL_RECETAS = "com.example.bocado/recetas";
    private final UsuarioManager usuarioManager = new UsuarioManager(new UsuarioDAO());

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_ACCESS)
                .setMethodCallHandler((call, result) -> {

                    switch (call.method){
                        case "loginJava":
                            String usuario = call.argument("usuario");
                            String contrasena = call.argument("contrasena");

                            UsuarioManager.login(usuario, contrasena, new LoginCallback() {
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

                        case "registerJava":
                            Usuario nuevoU = new Usuario();
                            nuevoU.setNombre(call.argument("nombre"));
                            nuevoU.setApellido(call.argument("apellido"));
                            nuevoU.setCorreo(call.argument("email"));
                            nuevoU.setUsuario(call.argument("usuario"));
                            nuevoU.setContrasena(call.argument("password"));
                            nuevoU.setNacion(String.valueOf(call.argument("nacion")));
                            nuevoU.setGenero(String.valueOf(call.argument("genero")));
                            nuevoU.setFecha_Nacimiento(call.argument("fechaNacimiento"));

                            UsuarioManager.registrar(nuevoU, new LoginCallback() {
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
                            new Thread(() -> {
                                try {
                                    RecetaDAO.Crear(call.arguments(), new LoginCallback() {
                                        @Override
                                        public void onSuccess(String result) {

                                        }

                                        @Override
                                        public void onError(String code, String message, Object details) {

                                        }
                                    });
                                    runOnUiThread(() -> result.success("OK"));
                                } catch (Exception e) {
                                    runOnUiThread(() -> result.error("DB_ERROR", e.getMessage(), null));
                                }
                            }).start();
                            break;

                        default:
                            result.notImplemented();
                    }
                });
    }

}