package com.example.bocado.DAO.Interfaces;

public interface IInteraccion {
    void toggleInteraccion(int idUsuario, int idReceta, String tipo, boolean isAdding, CallbackCB cb);
    void fetchMisInteracciones(int idUsuario, int idReceta, CallbackCB cb);
    void fetchComentarios(int idReceta, int idUsuario, CallbackCB cb);
    void enviarComentario(int idReceta, int idUsuario, String comentario, Integer idPadre, Double calificacion, CallbackCB cb);
}
