package com.example.bocado.Managers;

import com.example.bocado.DAO.IUsuarioDAO;
import com.example.bocado.DAO.LoginCallback;
import com.example.bocado.entidades.Usuario;
import org.json.JSONObject;

public class UsuarioManager {
    private final IUsuarioDAO usuarioDAO;

    public UsuarioManager(IUsuarioDAO usuarioDAO) {
        this.usuarioDAO = usuarioDAO;
    }
    public void registrar(Usuario u, LoginCallback cb) {
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

        usuarioDAO.registrar(u, cb);
    }
    public void login(String usuario, String contrasena, LoginCallback cb) {
        if (usuario.trim().isEmpty() || contrasena.trim().isEmpty()) {
            cb.onError("NEGOCIO", "Debe ingresar sus credenciales para continuar.", null);
            return;
        }

        usuarioDAO.login(usuario, contrasena, cb);
    }
    public void actualizar(int idUsuario, JSONObject actualizaciones, LoginCallback cb) {
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

        usuarioDAO.actualizar(idUsuario, actualizaciones, cb);
    }
    public void eliminar(int idUsuario, LoginCallback cb) {
        usuarioDAO.eliminar(idUsuario, cb);
    }
}