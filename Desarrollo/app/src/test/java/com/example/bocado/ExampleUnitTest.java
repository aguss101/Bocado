package com.example.bocado;

import com.example.bocado.DAO.AlimentoDAO;
import com.example.bocado.DAO.ConexionDB;
import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.Estaticos.Query;
import com.example.bocado.entidades.Alimento;
import com.example.bocado.entidades.Alimento_Nutriente;
import com.example.bocado.entidades.Nutriente;
import com.example.bocado.entidades.Usuario;

import org.junit.Test;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.List;


public class ExampleUnitTest {
    @Test
    public void listar_name_users() {
//
//        System.out.println(System.getProperty("user.dir"));
//        try
//        {
//            ConexionDB cdb = new ConexionDB();
//            cdb.Conectar();
//            cdb.Consultar(Query.getUsersComplete(null, null));
//            cdb.Leer();
//            ResultSet rs = cdb.getLector();
//            ResultSetMetaData md = rs.getMetaData();
//            int columnCount = md.getColumnCount();
//            while(cdb.getLector().next()){
//                for (int i = 1; i <= columnCount; i++) {
//                    String columnName = md.getColumnName(i);
//                    Object value = rs.getObject(i);
//
//                    System.out.println(columnName + ": " + value);
//                }
//                System.out.println("----");
//            }
//            /*
//            List<Usuario> usuarios = UsuarioDAO.Listar();
//            for(Usuario u : usuarios) {
//                System.out.println(u.getUsuario() + " - " + u.getNombre());
//            }*/
//        } catch(Exception e)
//        {
//            e.printStackTrace();
//        }
        try
        {
            List<Alimento> lista = new AlimentoDAO().Listar();
            for(Alimento aux : listaqr){
                System.out.println(aux.getNombre() + ", ");
                for(Alimento_Nutriente nt : aux.getListaNutrientes()){
                    System.out.println(nt.getNutriente().getNombre());
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}