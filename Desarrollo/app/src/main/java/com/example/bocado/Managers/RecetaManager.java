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

    // ── Lectores (Fase 2: encapsulados desde RecetasChannel) ──────────────────────
    public void feed(String seed, Integer limit, Integer offset, CallbackCB cb) {
        recetaDAO.feedAleatorio(
                seed,
                limit != null ? limit : 10,
                offset != null ? offset : 0,
                cb);
    }

    public void listarPorUsuario(Integer idUsuario, Integer limit, Integer offset, CallbackCB cb) {
        if (idUsuario == null) {
            cb.onError(ErrorCode.NEGOCIO, "Falta el id del usuario.", null);
            return;
        }
        recetaDAO.listarPorUsuario(idUsuario, limit, offset, cb);
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

}