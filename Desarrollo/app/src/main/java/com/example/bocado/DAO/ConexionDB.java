package com.example.bocado.DAO;
import com.example.bocado.BuildConfig;

import java.sql.*;

public class ConexionDB {
    private Connection conexion ;
    private PreparedStatement comando;
    private ResultSet lector;

    public void Conectar() throws SQLException
    {
        conexion = DriverManager.getConnection(BuildConfig.SUPABASE_URL);
    }
    public void Consultar(String sql) throws SQLException
    {
        comando = conexion.prepareStatement(sql);
    }
    public void Leer() throws SQLException
    {
        lector = comando.executeQuery();
    }
    public void SetearParametro(Object valor, int columna) throws SQLException
    {
        comando.setObject(columna, valor);
    }
    public ResultSet getLector()
    {
        return lector;
    }
    public int EjecutarAcccion() throws SQLException
    {
        comando.executeUpdate();
        ResultSet llaves = comando.getGeneratedKeys();
        return llaves.next() ? llaves.getInt(1) : -1;
        ///Retorna el numero de id generado o -1 en su defecto. Depende de la query que hagas en el DAO.\\\
        ///Borrar si no lo usamos...\\\
    }
    public void Cerrar()
    {
        try
        {
            if(lector != null) lector.close();
        } catch (Exception e){}

        try
        {
            if(comando != null) comando.close();
        }catch (Exception e){}

        try
        {
            if(conexion != null) conexion.close();
        }  catch (Exception e){}
    }
    public void testConexion() {
        System.out.println("--- Iniciando prueba de conexión ---");
        try {
            Conectar();
            System.out.println("¡Conexión exitosa a la base de datos!");
        } catch (SQLException e) {
            System.out.println("Error al conectar: " + e.getMessage());
        }
    }
}
