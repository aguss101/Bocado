package com.example.bocado.DAO;

import com.example.bocado.entidades.Usuario;
import org.json.JSONObject;

public interface IUsuarioDAO {
    void login(String usuario, String contrasena, LoginCallback cb);
    void registrar(Usuario nuevoUsuario, LoginCallback cb);
    void actualizar(int idUsuario, JSONObject camposActualizados, LoginCallback cb);
    void eliminar(int idUsuario, LoginCallback cb);

}