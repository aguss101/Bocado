package com.example.bocado.DAO.Interfaces;

import com.example.bocado.entidades.Usuario;
import org.json.JSONObject;

public interface IUsuario {
    void loginOrCreateGoogle(String email, String googleId, String nombre, String apellido, String foto, CallbackCB cb);
    void login(String usuario, String contrasena, CallbackCB cb);
    void registrar(Usuario nuevoUsuario, CallbackCB cb);
    void actualizar(int idUsuario, JSONObject camposActualizados, CallbackCB cb);
    void eliminar(int idUsuario, CallbackCB cb);
    void seguirUsuario(int idSeguidor, int idSeguido, CallbackCB cb);
    void dejarDeSeguir(int idSeguidor, int idSeguido, CallbackCB cb);

}