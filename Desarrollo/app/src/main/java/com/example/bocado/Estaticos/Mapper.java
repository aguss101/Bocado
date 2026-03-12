package com.example.bocado.Estaticos;

import com.example.bocado.DAO.ConexionDB;
import com.example.bocado.entidades.*;

import java.sql.SQLException;
import java.sql.Timestamp;

public class Mapper {
    public static Usuario getUsuario(ConexionDB acceso) throws SQLException {

        return new Usuario(
                acceso.getLector().getInt("id"),
                acceso.getLector().getInt("id_cuenta"),
                acceso.getLector().getInt("id_nacion"),
                acceso.getLector().getInt("id_genero"),
                acceso.getLector().getString("nombre"),
                acceso.getLector().getString("apellido"),
                acceso.getLector().getString("correo"),
                acceso.getLector().getString("usuario"),
                acceso.getLector().getString("contraseña"),
                acceso.getLector().getTimestamp("fecha_nacimiento"),
                acceso.getLector().getTimestamp("fecha_creacion"),
                acceso.getLector().getTimestamp("fecha_acceso"),
                acceso.getLector().getBoolean("activo"),
                acceso.getLector().getBoolean("visibilidad"),
                acceso.getLector().getBytes("foto"),
                acceso.getLector().getBytes("banner")
        );
    }

    public static void setUsuario(ConexionDB acceso, Usuario u) throws SQLException {
                u.setId(acceso.getLector().getInt("id"));
                u.setId_Cuenta(acceso.getLector().getInt("id_cuenta"));
                u.setId_Nacion(acceso.getLector().getInt("id_nacion"));
                u.setId_Genero(acceso.getLector().getInt("id_genero"));
                u.setNombre(acceso.getLector().getString("nombre"));
                u.setApellido(acceso.getLector().getString("apellido"));
                u.setCorreo(acceso.getLector().getString("correo"));
                u.setUsuario(acceso.getLector().getString("usuario"));
                u.setContrasena(acceso.getLector().getString("contrasena"));
                u.setFecha_Nacimiento(new Timestamp(acceso.getLector().getDate("fecha_nacimiento").getTime()));
                u.setFecha_Creacion(acceso.getLector().getTimestamp("fecha_creacion"));
                u.setFecha_Acceso(acceso.getLector().getTimestamp("fecha_acceso"));
                u.setActivo(acceso.getLector().getBoolean("activo"));
                u.setVisibilidad(acceso.getLector().getBoolean("visibilidad"));
                u.setFoto(acceso.getLector().getBytes("foto"));
                u.setBanner(acceso.getLector().getBytes("banner"));
    }
    /*
    public static void modUsuario(ConexionDB acceso, Usuario u) throws SQLException {
                u.setId(acceso.getLector().getInt("id"));
                u.setId_Cuenta(acceso.getLector().getInt("id_cuenta"));
                u.setId_Nacion(acceso.getLector().getInt("id_nacion"));
                u.setId_Genero(acceso.getLector().getInt("id_genero"));
                u.setNombre(acceso.getLector().getString("nombre"));
                u.setApellido(acceso.getLector().getString("apellido"));
                u.setCorreo(acceso.getLector().getString("correo"));
                u.setUsuario(acceso.getLector().getString("usuario"));
                u.setContrasena(acceso.getLector().getString("contrasena"));
                u.setFecha_Nacimiento(new Timestamp(acceso.getLector().getDate("fecha_nacimiento").getTime()));
                u.setFecha_Creacion(acceso.getLector().getTimestamp("fecha_creacion"));
                u.setFecha_Acceso(acceso.getLector().getTimestamp("fecha_acceso"));
                u.setActivo(acceso.getLector().getBoolean("activo"));
                u.setVisibilidad(acceso.getLector().getBoolean("visibilidad"));
                u.setFoto(acceso.getLector().getBytes("foto"));
                u.setBanner(acceso.getLector().getBytes("banner"));
    }*/
    // Mapeo de todas las entidades
}
