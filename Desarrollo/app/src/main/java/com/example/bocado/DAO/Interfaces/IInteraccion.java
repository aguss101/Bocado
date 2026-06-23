package com.example.bocado.DAO.Interfaces;

public interface IInteraccion {
    void toggleInteraccion(int idUsuario, int idReceta, String tipo, boolean isAdding, CallbackCB cb);
    void fetchComentarios(int idReceta, CallbackCB cb);
    void enviarComentario(int idReceta, int idUsuario, String comentario, Integer idPadre, CallbackCB cb);
}
