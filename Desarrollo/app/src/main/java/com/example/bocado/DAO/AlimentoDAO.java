package com.example.bocado.DAO;

import com.example.bocado.entidades.Alimento;
import com.example.bocado.entidades.Medida;
import com.example.bocado.entidades.Usuario;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class AlimentoDAO
{
    private ConexionDB conexion = null;
/*    public List<Alimento> Listar() throws SQLException
    {
        conexion = new ConexionDB();
        List<Alimento> listado = new ArrayList<>();

        try
        {
            conexion.Conectar();
            conexion.Consultar("SELECT a.nombre as nombre_Alimento, u.medida as user_Usuario, " +
                    "m.nombre as nombre_Medida, n.nombre as nombre_Nutriente, an.valor100gr FROM Alimentos a " +
                    "INNER JOIN Usuarios u ON a.id_usuario = u.id " +
                    "INNER JOIN Medidas m ON a.id_medida = m.id " +
                    "INNER JOIN Alimentos_Nutrientes an ON a.id = an.id_alimento " +
                    "INNER JOIN Nutrientes n ON an.id_nutriente = n.id");
            conexion.Leer();
            while(conexion.getLector().next())

                if(aux == null)
                {
                    Alimento aux = new Alimento();
                    aux.setNombre(conexion.getLector().getString("nombre_Alimento"));
                    Usuario u = new Usuario();
                    u.setUsuario(conexion.getLector().getString("user_Usuario"));
                    aux.setUsuario(u);
                    Medida m = new Medida();
                    m.setNombre(conexion.getLector().getString("nombre_Medida"));
                    aux.setMedida(m);
                }

            }
        } catch (SQLException e)
        {
            throw e;
        } finally
        {
            conexion.Cerrar();
        }

        return listado;
    }*/
}
