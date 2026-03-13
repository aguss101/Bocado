package com.example.bocado.DAO;
import com.example.bocado.Estaticos.Query;
import com.example.bocado.Estaticos.Mapper;
import com.example.bocado.entidades.Usuario;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class UsuarioDAO
{
    ///Inserts
    public static void Crear(Usuario u)throws SQLException
    {
        ConexionDB acceso = new ConexionDB();
        try
        {
            acceso.Conectar();
            acceso.Consultar(Query.createUsers(u));
            Mapper.createUsuario(acceso, u);
            acceso.EjecutarAcccion();
        }
        catch(SQLException e)
        {
            throw e;
        }
        finally
        {
            acceso.Cerrar();
        }
    }
    /// Listados
    public static List<Usuario> Listar() throws SQLException
    {
        List<Usuario> usuarios = new ArrayList<>();
        ConexionDB acceso = new ConexionDB(); //creemos una de estas para cada vez que un metodo necesita conexion a la DB. Asi no se pisa con otras conexiones.
        try
        {
            acceso.Conectar();
            acceso.Consultar(Query.getUsers(null,null));
            acceso.Leer();
            while(acceso.getLector().next())
            {
                Usuario aux = new Usuario();
                Mapper.setUsuario(acceso, aux);
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

    /// Modifys

    /// Deletes


}
