package com.example.bocado;

import org.junit.Test;

import java.sql.SQLException;

import static org.junit.Assert.*;

/**
 * Example local unit test, which will execute on the development machine (host).
 *
 * @see <a href="http://d.android.com/tools/testing">Testing documentation</a>
 */
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
        System.out.println("--- Prueba finalizada ---");
    }
}