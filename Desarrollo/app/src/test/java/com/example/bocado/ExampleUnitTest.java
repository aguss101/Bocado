package com.example.bocado;

import com.example.bocado.DAO.UsuarioDAO;
import com.example.bocado.entidades.Usuario;

import org.junit.Test;
import java.util.List;


public class ExampleUnitTest {
    @Test
    public void listar_name_users() {
        try
        {
            List<Usuario> lista = UsuarioDAO.Listar();

            for(Usuario aux : lista)
            {
                System.out.print(aux.getNombre() + "\r\n");
            }
        } catch(Exception e)
        {
            e.printStackTrace();
        }
    }
}