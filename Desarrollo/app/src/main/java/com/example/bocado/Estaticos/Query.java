package com.example.bocado.Estaticos;

import com.example.bocado.entidades.*;

public class Query {
    ///Inserts
    public static String createUsers(Usuario u){
        String query = """
                INSERT INTO "Usuarios" (id_cuenta, id_nacion, id_genero, nombre, apellido, correo, usuario, contrasena, 
                fecha_nacimiento, fecha_creacion, fecha_acceso, activo, visibilidad, foto, banner) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """;

        return query;
    }
    /// Listados
    public static String getUsersComplete(Integer userID, Integer accountID){
        String query = """
                SELECT
                    u.id AS id,
                    cuentas.nombre AS cuenta,
                    cuentas.id AS id_cuenta,
                    naciones.nombre AS pais,
                    naciones.id AS id_nacion,
                    generos.nombre AS genero,
                    generos.id AS id_genero,
                    u.nombre, u.apellido,
                    u.correo, u.usuario, u.contrasena,
                    u.fecha_nacimiento, u.fecha_creacion, u.fecha_acceso,
                    u.activo, u.visibilidad, u.foto, u.banner
                FROM usuarios u
                JOIN cuentas ON u.id_cuenta = cuentas.id
                JOIN naciones ON u.id_nacion = naciones.id
                JOIN generos ON u.id_genero = generos.id
        """;
        if(userID != null){
            query += " WHERE usuarios.id = " + userID;
        }else if(accountID != null){
            query += " WHERE usuarios.id_cuenta = " + accountID;
        }
        return query;
    }
    public static String getUsers(Integer userID, Integer accountID){
        String query = """
                SELECT
                    u.id AS id,
                    cuentas.nombre AS cuenta,
                    naciones.nombre AS pais,
                    generos.nombre AS genero,
                    u.nombre, u.apellido,
                    u.correo, u.usuario, u.contrasena,
                    u.fecha_nacimiento, u.fecha_creacion, u.fecha_acceso,
                    u.activo, u.visibilidad, u.foto, u.banner
                FROM usuarios u
                JOIN cuentas ON u.id_cuenta = cuentas.id
                JOIN naciones ON u.id_nacion = naciones.id
                JOIN generos ON u.id_genero = generos.id
        """;
        if(userID != null){
            query += " WHERE usuarios.id = " + userID;
        }else if(accountID != null){
            query += " WHERE usuarios.id_cuenta = " + accountID;
        }
        return query;
    }
    public static String createAlimento(Alimento a){
        String query = """
                INSERT INTO "Alimentos" (id, nombre, id_usuario, id_medida) 
                VALUES (?, ?, ?, ?)
        """;

        return query;
    }
    public static String getAlimento(Integer foodID, Integer userID){
        String query = """
                SELECT
                alimentos.id AS id,
                alimentos.nombre,
                usuarios.usuario AS usuario,

                MAX(CASE WHEN nutrientes.nombre = 'Proteinas' THEN alimentos_nutrientes.valor100gr END) AS proteinas,
                MAX(CASE WHEN nutrientes.nombre = 'Carbohidratos' THEN alimentos_nutrientes.valor100gr END) AS carbohidratos,
                MAX(CASE WHEN nutrientes.nombre = 'Grasas' THEN alimentos_nutrientes.valor100gr END) AS grasas,
                MAX(CASE WHEN nutrientes.nombre = 'Vitamina C' THEN alimentos_nutrientes.valor100gr END) AS vitamina_c

                FROM alimentos
                LEFT JOIN usuarios ON usuarios.id = alimentos.id_usuario
                LEFT JOIN alimentos_nutrientes ON alimentos_nutrientes.id_alimento = alimentos.id
                LEFT JOIN nutrientes ON nutrientes.id = alimentos_nutrientes.id_nutriente
            """;
        if(foodID != null){
            query += "WHERE alimentos.id = " + foodID + " ";
        }else if(userID != null){
            query += "WHERE alimentos.id_usuario = " + userID + " ";
        }

        query += "GROUP BY alimentos.id, alimentos.nombre, usuarios.usuario";

        return query;
    }
    public static String getRecipes(Integer recipeID, Integer userID){
        String query = """
            SELECT
            recetas.id AS id,
            usuarios.usuario AS usuario,
            recetas.nombre AS nombre,
            recetas.calorias_totales AS calorias,
            recetas.porciones AS cantidad_porciones,
            recetas.porciones_peso AS peso_porcion,
            recetas.instrucciones AS instrucciones,
            recetas.precio AS costo,
            recetas.fecha_creacion AS fecha,
            recetas.visibilidad AS visibilidad,
            STRING_AGG(
                '[' || alimentos.nombre || ',' || recetas_alimentos.cantidad || ',' || recetas_alimentos.precio || ']',
                ','
            ) AS alimentos,
            STRING_AGG(
                '[' || etiquetas.nombre || ']', ','
            ) AS etiquetas
            FROM recetas
            JOIN usuarios ON usuarios.id = recetas.id_usuario
            JOIN recetas_alimentos ON recetas.id = recetas_alimentos.id_receta
            JOIN alimentos ON alimentos.id = recetas_alimentos.id_alimento
            JOIN etiquetas_recetas ON recetas.id = etiquetas_recetas.id_recetas
            JOIN etiquetas ON etiquetas.id_etiqueta = etiquetas_recetas.id_etiquetas
            """;

        if(recipeID != null){
            query += " WHERE recetas.id = " + recipeID + " ";
        }else if(userID != null){
            query += " WHERE recetas.id_usuario = " + userID + " ";
        }

        query += " GROUP BY recetas.id, usuarios.usuario";

        return query;
    }
    /// Modifys

    /// Deletes
}
