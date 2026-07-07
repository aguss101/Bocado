package com.example.bocado.DAO.Interfaces;

import com.example.bocado.Entidades.Usuario;
import org.json.JSONObject;

public interface IUsuario {
    void loginOrCreateGoogle(String email, String googleId, String nombre, String apellido, String foto, CallbackCB cb);
    void login(String usuario, String contrasena, CallbackCB cb);
    void register(Usuario nuevoUsuario, CallbackCB cb);
    void update(int idUsuario, JSONObject camposActualizados, CallbackCB cb);
    void delete(int idUsuario, CallbackCB cb);
    void followUser(int idSeguidor, int idSeguido, CallbackCB cb);
    void stopFollow(int idSeguidor, int idSeguido, CallbackCB cb);
    void buscarUsuario(String query, CallbackCB cb);
}