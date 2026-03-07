package com.example.bocado.DAO;
import com.example.bocado.entidades.Usuario;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class UsuarioDAO
{
    public static List<Usuario> Listar() throws SQLException
    {
        List<Usuario> usuarios = new ArrayList<>();
        ConexionDB acceso = new ConexionDB(); //creemos una de estas para cada vez que un metodo necesita conexion a la DB. Asi no se pisa con otras conexiones.
        try
        {
            acceso.Conectar();
            acceso.Consultar("SELECT id,id_cuenta,id_nacion,id_genero,nombre,apellido,correo,usuario,contrasena,fecha_nacimiento,fecha_creacion,fecha_acceso,activo,visibilidad,foto,banner FROM \"Usuarios\"");            acceso.Leer();
            while(acceso.getLector().next())
            {
                Usuario aux = new Usuario();
                aux.setId(acceso.getLector().getInt("id"));
                aux.setId_Cuenta(acceso.getLector().getInt("id_cuenta"));
                aux.setId_Nacion(acceso.getLector().getInt("id_nacion"));
                aux.setId_Genero(acceso.getLector().getInt("id_genero"));
                aux.setNombre(acceso.getLector().getString("nombre"));
                aux.setApellido(acceso.getLector().getString("apellido"));
                aux.setCorreo(acceso.getLector().getString("correo"));
                aux.setUsuario(acceso.getLector().getString("usuario"));
                aux.setContraseña(acceso.getLector().getString("contrasena"));
                aux.setFecha_Nacimiento(acceso.getLector().getDate("fecha_nacimiento"));
                aux.setFecha_Creacion(acceso.getLector().getTimestamp("fecha_creacion"));
                aux.setFecha_Acceso(acceso.getLector().getTimestamp("fecha_acceso"));
                aux.setActivo(acceso.getLector().getBoolean("activo"));
                aux.setVisibilidad(acceso.getLector().getBoolean("visibilidad"));
                aux.setFoto(acceso.getLector().getBytes("foto"));
                aux.setBanner(acceso.getLector().getBytes("banner"));
                usuarios.add(aux);
            }
        } catch (SQLException e)
        {
            throw e;
        }
        finally
        {
            acceso.Cerrar();
        }
        return usuarios;
    }
}
