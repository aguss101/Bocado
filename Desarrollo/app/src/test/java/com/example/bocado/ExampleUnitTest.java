package com.example.bocado;

import DAO.ConexionDB;
import DAO.UsuarioDAO;
import Model.Usuario;
import org.junit.Test;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import static org.junit.Assert.*;

public class ExampleUnitTest {
    @Test
    public void testConexion() {
        System.out.println("--- Iniciando prueba de conexión ---");
        try {
            ConexionDB.Conectar();
            System.out.println("¡Conexión exitosa a la base de datos!");
        } catch (SQLException e) {
            System.out.println("Error al conectar: " + e.getMessage());
            fail("La conexión falló");
        }

        try
        {
            List<Usuario> lista = UsuarioDAO.Listar();

            for(Usuario aux : lista)
            {
                System.out.println(aux.getNombre() + "\r\n");
            }
        } catch(Exception e)
        {

        }

        System.out.println("--- Prueba finalizada ---");
    }
}