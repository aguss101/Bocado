package com.example.bocado.Managers;

import com.example.bocado.DAO.Interfaces.IUsuario;
import com.example.bocado.DAO.Interfaces.CallbackCB;
import com.example.bocado.Entidades.Usuario;
import com.example.bocado.Estaticos.ErrorCode;
import org.json.JSONObject;

public class UsuarioManager {
    private final IUsuario usuarioDAO;

    public UsuarioManager(IUsuario usuarioDAO) {
        this.usuarioDAO = usuarioDAO;
    }
    public void loginOrCreateGoogle(String email, String googleId, String nombre, String apellido, String foto, CallbackCB cb){
        if (email == null || email.trim().isEmpty() || googleId == null || googleId.trim().isEmpty()) {
            cb.onError("NEGOCIO", "El correo y el ID de Google son obligatorios para continuar.", null);
            return;
        }

        if (!email.contains("@") || !email.contains(".")) {
            cb.onError("NEGOCIO", "El formato del correo electrónico provisto por Google es inválido.", null);
            return;
        }

        usuarioDAO.loginOrCreateGoogle(email, googleId, nombre, apellido, foto, cb);
    }
    public void register(Usuario u, CallbackCB cb) {
        if (u.getNombre().trim().isEmpty() || u.getCorreo().trim().isEmpty() || u.getContrasena().trim().isEmpty()) {
            cb.onError("NEGOCIO", "El nombre, correo y contraseña son obligatorios.", null);
            return;
        }

        if (!u.getCorreo().contains("@") || !u.getCorreo().contains(".")) {
            cb.onError("NEGOCIO", "El formato del correo electrónico es inválido.", null);
            return;
        }

        if (u.getContrasena().length() < 8) {
            cb.onError("NEGOCIO", "La contraseña debe tener al menos 8 caracteres.", null);
            return;
        }

        usuarioDAO.register(u, cb);
    }
    public void login(String usuario, String contrasena, CallbackCB cb) {
        if (usuario.trim().isEmpty() || contrasena.trim().isEmpty()) {
            cb.onError("NEGOCIO", "Debe ingresar sus credenciales para continuar.", null);
            return;
        }

        usuarioDAO.login(usuario, contrasena, cb);
    }
    public void update(int idUsuario, JSONObject actualizaciones, CallbackCB cb) {
        if (actualizaciones.length() == 0) {
            cb.onError("NEGOCIO", "No hay cambios para guardar.", null);
            return;
        }

        if (actualizaciones.has("contrasena")) {
            String nuevaPass = actualizaciones.optString("contrasena");
            if (nuevaPass.length() < 8) {
                cb.onError("NEGOCIO", "La nueva contraseña debe tener al menos 8 caracteres.", null);
                return;
            }
        }

        usuarioDAO.update(idUsuario, actualizaciones, cb);
    }
    public void delete(int idUsuario, CallbackCB cb) {
        usuarioDAO.delete(idUsuario, cb);
    }
    public void updatefollow(int idUsuarioSeguidor, int idUsuarioSeguido, Boolean siguiendo, CallbackCB cb){
        if(idUsuarioSeguidor == idUsuarioSeguido){
            cb.onError("NEGOCIO", "Un usuario no puede seguirse a si mismo", null);
            return;
        }

        if(siguiendo){
            usuarioDAO.stopFollow(idUsuarioSeguidor,idUsuarioSeguido, cb);
        } else {
            usuarioDAO.followUser(idUsuarioSeguidor,idUsuarioSeguido,cb);
        }
    }
    public void buscarUsuario(String query, CallbackCB cb){
        if(query == null || query.trim().isEmpty()){
            cb.onError(ErrorCode.NEGOCIO, "Falta el término de búsqueda.", null);
            return;
        }
        usuarioDAO.buscarUsuario(query, cb);
    }
}