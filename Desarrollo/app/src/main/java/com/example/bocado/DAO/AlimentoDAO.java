package com.example.bocado.DAO;

import com.example.bocado.entidades.*;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class AlimentoDAO
{
    ///Inserts
    ///
    /// Listados
        public List<Alimento> Listar() throws SQLException
    {
        ConexionDB acceso = new ConexionDB();
        List<Alimento> listado = new ArrayList<>();

        try
        {
            acceso.Conectar();
            acceso.Consultar("SELECT a.id, a.nombre as nombre_Alimento, u.medida as user_Usuario, " +
                    "m.nombre as nombre_Medida, n.nombre as nombre_Nutriente, an.valor100gr FROM Alimentos a " +
                    "INNER JOIN Usuarios u ON a.id_usuario = u.id " +
                    "INNER JOIN Medidas m ON a.id_medida = m.id " +
                    "INNER JOIN Alimentos_Nutrientes an ON a.id = an.id_alimento " +
                    "INNER JOIN Nutrientes n ON an.id_nutriente = n.id");
            acceso.Leer();
            Alimento aux = null;
            while(acceso.getLector().next())
            {
                if(acceso.getLector().getInt("id") != aux.getId() || aux == null)
                {
                    if(aux != null)
                    {
                        listado.add(aux);
                    }
                    aux = new Alimento();
                    aux.setId(acceso.getLector().getInt("id"));
                }
                Alimento_Nutriente an = new Alimento_Nutriente();
                Nutriente nt = new Nutriente();
                nt.setNombre(acceso.getLector().getString("nombre_Nutriente"));
                //Guardo un nutriente para despues guardarlo en el Alimento_Nutriente
                an.setNutriente(nt);
                an.setValor100gr(acceso.getLector().getInt("valor100gr"));
                aux.getListaNutrientes().add(an);
            }
            if(aux != null)
            {
                listado.add(aux);
            }
        } catch (SQLException e)
        {
            throw e;
        } finally
        {
            acceso.Cerrar();
        }

        return listado;
    }

    /// Modifys
    /// Deletes
}
