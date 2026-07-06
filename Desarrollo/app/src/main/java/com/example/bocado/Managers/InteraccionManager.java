package com.example.bocado.Managers;

import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.DAO.Interfaces.IInteraccion;
import com.example.bocado.Estaticos.ErrorCode;

public class InteraccionManager {
    private final IInteraccion interaccionDAO;

    public InteraccionManager(IInteraccion interaccionDAO) {
        this.interaccionDAO = interaccionDAO;
    }

    public void toggleInteraccion(Integer idUsuario, Integer idReceta, String tipo, Boolean isAdding, CallbackCB cb) {
        if (idUsuario == null || idReceta == null) {
            cb.onError(ErrorCode.NEGOCIO, "Faltan el usuario o la receta.", null);
            return;
        }
        if (tipo == null || (!tipo.equals("like") && !tipo.equals("save"))) {
            cb.onError(ErrorCode.NEGOCIO, "Tipo de interacción inválido.", null);
            return;
        }
        interaccionDAO.toggleInteraccion(idUsuario, idReceta, tipo, isAdding != null && isAdding, cb);
    }

    public void fetchMisInteracciones(Integer idUsuario, Integer idReceta, CallbackCB cb) {
        if (idUsuario == null || idReceta == null) {
            cb.onError(ErrorCode.NEGOCIO, "Faltan el usuario o la receta.", null);
            return;
        }
        interaccionDAO.fetchMisInteracciones(idUsuario, idReceta, cb);
    }

    public void fetchComentarios(Integer idReceta, CallbackCB cb) {
        if (idReceta == null) {
            cb.onError(ErrorCode.NEGOCIO, "Falta el id de la receta.", null);
            return;
        }
        interaccionDAO.fetchComentarios(idReceta, cb);
    }

    public void enviarComentario(Integer idReceta, Integer idUsuario, String comentario, Integer idPadre, Double calificacion, CallbackCB cb) {
        if (idReceta == null || idUsuario == null || comentario == null || comentario.trim().isEmpty()) {
            cb.onError(ErrorCode.NEGOCIO, "Faltan datos obligatorios del comentario.", null);
            return;
        }
        interaccionDAO.enviarComentario(idReceta, idUsuario, comentario, idPadre, calificacion, cb);
    }
}
