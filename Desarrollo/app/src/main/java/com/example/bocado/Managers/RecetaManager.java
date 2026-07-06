package com.example.bocado.Managers;

import com.example.bocado.DAO.Interfaces.IReceta;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Estaticos.ErrorCode;
import io.flutter.plugin.common.MethodChannel;
import com.example.bocado.DAO.RecetaDAO;
import java.util.Map;

public class RecetaManager implements IReceta {

    private static RecetaManager instance;
    private final RecetaDAO recetaDAO;

    private RecetaManager() {
        this.recetaDAO = new RecetaDAO();
    }

    public static RecetaManager getInstance() {
        if (instance == null) {
            instance = new RecetaManager();
        }
        return instance;
    }

    @Override
    public void create(Map<String, Object> args, MethodChannel.Result result) {
        try {
            if (args == null || !args.containsKey("nombre") || !args.containsKey("id_usuario")) {
                result.error("ARGS_INVALIDOS", "Faltan parámetros obligatorios", null);
                return;
            }

            recetaDAO.create(args, new CallbackCB() {
                @Override
                public void onSuccess(String data) {
                    result.success(data);
                }

                @Override
                public void onError(String code, String message, Object details) {
                    result.error(code, message, details);
                }
            });

        } catch (Exception e) {
            result.error("ERROR_MANAGER", "Error al procesar la receta: " + e.getMessage(), null);
        }
    }

    @Override
    public void getById(int idReceta, MethodChannel.Result result) {
        try {
            if (idReceta <= 0) {
                result.error("ID_INVALIDO", "El ID de la receta debe ser mayor a 0", null);
                return;
            }

            recetaDAO.getById(idReceta, new CallbackCB() {
                @Override
                public void onSuccess(String data) {
                    result.success(data);
                }

                @Override
                public void onError(String code, String message, Object details) {
                    result.error(code, message, details);
                }
            });

        } catch (Exception e) {
            result.error("ERROR_MANAGER", "Error al recuperar la receta: " + e.getMessage(), null);
        }
    }

    @Override
    public void update(Map<String, Object> args, MethodChannel.Result result) {
        try {
            if (args == null || !args.containsKey("nombre") || !args.containsKey("id_usuario")) {
                result.error("ARGS_INVALIDOS", "Faltan parámetros obligatorios", null);
                return;
            }

            recetaDAO.update(args, new CallbackCB() {
                @Override
                public void onSuccess(String data) {
                    result.success(data);
                }

                @Override
                public void onError(String code, String message, Object details) {
                    result.error(code, message, details);
                }
            });

        } catch (Exception e) {
            result.error("ERROR_MANAGER", "Error al procesar la receta: " + e.getMessage(), null);
        }
    }

    public void feed(String seed, Integer limit, Integer offset, Integer viewerId, CallbackCB cb) {
        recetaDAO.feedAleatorio(
                seed,
                limit != null ? limit : 10,
                offset != null ? offset : 0,
                viewerId,
                cb);
    }

    public void listarPorUsuario(Integer idUsuario, Integer limit, Integer offset, CallbackCB cb) {
        if (idUsuario == null) {
            cb.onError(ErrorCode.NEGOCIO, "Falta el id del usuario.", null);
            return;
        }
        recetaDAO.listarPorUsuario(idUsuario, limit, offset, cb);
    }

    public void misRecetasCompleto(Integer idUsuario, CallbackCB cb) {
        if (idUsuario == null) {
            cb.onError(ErrorCode.NEGOCIO, "Falta el id del usuario.", null);
            return;
        }
        recetaDAO.misRecetasCompleto(idUsuario, cb);
    }

    public void listarGuardados(Integer idUsuario, Integer limit, Integer offset, CallbackCB cb) {
        if (idUsuario == null) {
            cb.onError(ErrorCode.NEGOCIO, "Falta el id del usuario.", null);
            return;
        }
        recetaDAO.listarGuardados(idUsuario, limit, offset, cb);
    }

    public void detalle(Integer idReceta, CallbackCB cb) {
        if (idReceta == null) {
            cb.onError(ErrorCode.NEGOCIO, "Falta el id de la receta.", null);
            return;
        }
        recetaDAO.obtenerDetalle(idReceta, cb);
    }

    public void eliminarReceta(Integer idReceta, Integer idUsuario, CallbackCB cb) {
        if (idReceta == null || idUsuario == null) {
            cb.onError("INVALID_ARGS", "Faltan parámetros (id_receta o id_usuario)", null);
            return;
        }

        recetaDAO.eliminarReceta(idReceta, idUsuario, new CallbackCB() {
            @Override
            public void onSuccess(String data) {
                try {
                    org.json.JSONObject obj = new org.json.JSONObject(data);
                    if (!obj.optBoolean("ok", false)) {
                        cb.onError(ErrorCode.NEGOCIO, obj.optString("mensaje", "No se pudo eliminar la receta"), null);
                        return;
                    }
                    String foto = obj.isNull("foto") ? null : obj.optString("foto", null);
                    if (foto != null && !foto.isEmpty()) {
                        limpiarStorage(foto);
                    }
                    cb.onSuccess(data);
                } catch (Exception e) {
                    cb.onError(ErrorCode.PARSE_ERROR, e.getMessage(), null);
                }
            }

            @Override
            public void onError(String code, String msg, Object details) {
                cb.onError(code, msg, details);
            }
        });
    }

    private void limpiarStorage(String fotoConcatenada) {
        okhttp3.Callback noop = new okhttp3.Callback() {
            @Override public void onFailure(okhttp3.Call call, java.io.IOException e) { }
            @Override public void onResponse(okhttp3.Call call, okhttp3.Response response) throws java.io.IOException {
                if (response.body() != null) response.body().close();
            }
        };
        final String marcador = "/storage/v1/object/public/";
        for (String url : fotoConcatenada.split("\\|")) {
            if (url == null || !url.contains(marcador)) continue;
            String objectPath = url.substring(url.indexOf(marcador) + marcador.length());
            int q = objectPath.indexOf('?');
            if (q >= 0) objectPath = objectPath.substring(0, q);
            if (!objectPath.isEmpty()) {
                HttpClientManager.getInstance().deleteStorageObject(objectPath, noop);
            }
        }
    }

}