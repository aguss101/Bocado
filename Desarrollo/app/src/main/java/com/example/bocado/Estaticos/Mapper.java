package com.example.bocado.Estaticos;

import com.example.bocado.DAO.ConexionDB;
import com.example.bocado.entidades.*;

import java.sql.SQLException;
import java.sql.Timestamp;

public class Mapper {

    public static void createUsuario(ConexionDB acceso, Usuario u) throws SQLException
    {
        acceso.SetearParametro(u.getCuenta(),1);
        acceso.SetearParametro(u.getNacion(),2);
        acceso.SetearParametro(u.getGenero(),3);
        acceso.SetearParametro(u.getNombre(),4);
        acceso.SetearParametro(u.getApellido(),5);
        acceso.SetearParametro(u.getCorreo(),6);
        acceso.SetearParametro(u.getUsuario(),7);
        acceso.SetearParametro(u.getContrasena(),8);
        acceso.SetearParametro(u.getFecha_Nacimiento(),9);
        acceso.SetearParametro(u.getFecha_Creacion(),10);
        acceso.SetearParametro(u.getFecha_Acceso(),11);
        acceso.SetearParametro(u.isActivo(),12);
        acceso.SetearParametro(u.isVisibilidad(),13);
        acceso.SetearParametro(u.getFoto(),14);
        acceso.SetearParametro(u.getBanner(),15);
    }
    public static Usuario getUsuario(ConexionDB acceso) throws SQLException {

        return new Usuario(
                acceso.getLector().getInt("id"),
                acceso.getLector().getString("cuenta_Nombre"),
                acceso.getLector().getString("nacion_Nombre"),
                acceso.getLector().getString("genero_Nombre"),
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
                u.setCuenta(acceso.getLector().getString("cuenta_Nombre"));
                u.setNacion(acceso.getLector().getString("nacion_Nombre"));
                u.setGenero(acceso.getLector().getString("genero_Nombre"));
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
    //Alimento
    public static void createAlimento (ConexionDB acceso, Alimento a) throws SQLException
    {
        acceso.SetearParametro(a.getId(),1);
        acceso.SetearParametro(a.getNombre(),2);
        acceso.SetearParametro(a.getUsuario(),3);
        acceso.SetearParametro(a.getMedida(),4);

    }
    // Mapeo de todas las entidades
}
