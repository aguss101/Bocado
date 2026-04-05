package com.example.bocado.Managers;

import com.example.bocado.DAO.Interfaces.IReceta;
import com.example.bocado.DAO.Interfaces.CallbackCB;
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
    public void crear(Map<String, Object> args, MethodChannel.Result result) {
        try {
            if (args == null || !args.containsKey("nombre") || !args.containsKey("id_usuario")) {
                result.error("ARGS_INVALIDOS", "Faltan parámetros obligatorios", null);
                return;
            }

            recetaDAO.crear(args, new CallbackCB() {
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
}