package com.example.bocado.Managers;

import com.example.bocado.BuildConfig;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DataBaseManager {
    private static DataBaseManager instance;
    private DataBaseManager() {}
    public static DataBaseManager getInstance() {
        if (instance == null) {
            instance = new DataBaseManager();
        }
        return instance;
    }
    public interface ResultSetMapper<T> {
        T map(ResultSet rs) throws SQLException;
    }
    public <T> List<T> ejecutarConsulta(String sql, ResultSetMapper<T> mapper, Object... params) {
        List<T> resultados = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(BuildConfig.SUPABASE_URL);
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                stmt.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    resultados.add(mapper.map(rs));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return resultados;
    }
    public <T> T ejecutarConsultaUnica(String sql, ResultSetMapper<T> mapper, Object... params) {

        try (Connection conn = DriverManager.getConnection(BuildConfig.SUPABASE_URL);
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            for (int i = 0; i < params.length; i++) {
                stmt.setObject(i + 1, params[i]);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapper.map(rs);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }
    public boolean ejecutarAccion(String sql, Object... params) {

        try (Connection conn = DriverManager.getConnection(BuildConfig.SUPABASE_URL);
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            for (int i = 0; i < params.length; i++) {
                stmt.setObject(i + 1, params[i]);
            }

            stmt.executeUpdate();
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
    public int ejecutarInsertConID(String sql, Object... params) {

        try (Connection conn = DriverManager.getConnection(BuildConfig.SUPABASE_URL);
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            for (int i = 0; i < params.length; i++) {
                stmt.setObject(i + 1, params[i]);
            }

            stmt.executeUpdate();

            try (ResultSet keys = stmt.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1;
    }
}