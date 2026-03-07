package DAO;

import java.sql.*;
public class ConexionDB {
    private static Connection conexion = null;
    private static PreparedStatement comando = null;
    private static ResultSet lector = null;

    public static void Conectar() throws SQLException
    {
        conexion = DriverManager.getConnection("jdbc:postgresql://db.sosbomunpwbgcezgfgzs.supabase.co:5432/postgres?user=postgres&password=Salami23738_19#msN");
    }
    public static void Consultar(String sql) throws SQLException
    {
        comando = conexion.prepareStatement(sql);
    }
    public static void Leer() throws SQLException
    {
        lector = comando.executeQuery();
    }
    public static void SetearParametro(Object valor, int columna) throws SQLException
    {
        comando.setObject(columna, valor);
    }
    public static ResultSet getLector()
    {
        return lector;
    }
    public static int EjecutarAcccion() throws SQLException
    {
        comando.executeUpdate();
        ResultSet llaves = comando.getGeneratedKeys();
        return llaves.next() ? llaves.getInt(1) : -1;
        ///Retorna el numero de id generado o -1 en su defecto. Depende de la query que hagas en el DAO.\\\
        ///Borrar si no lo usamos...\\\
    }
    public static void Cerrar()
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
}
