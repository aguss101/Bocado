package com.example.bocado.Estaticos;
public class Query {
    public static String getUsers(Integer userID){
        String query = """
                SELECT
                    usuarios.id AS id,
                    cuentas.nombre AS cuenta,
                    naciones.nombre AS pais,
                    generos.nombre AS genero,
                    usuarios.nombre, usuarios.apellido,
                    usuarios.correo, usuarios.usuario, usuarios.contrasena,
                    usuarios.fecha_nacimiento, usuarios.fecha_creacion, usuarios.fecha_acceso,
                    usuarios.activo, usuarios.visibilidad, usuarios.foto, usuarios.banner
                FROM usuarios
                JOIN cuentas ON usuarios.id_cuenta = cuentas.id
                JOIN naciones ON usuarios.id_nacion = naciones.id
                JOIN generos ON usuarios.id_genero = generos.id
        """;
        if(userID != null){
            query += " WHERE usuarios.id = " + userID;
        }
        return query;
    }
    public static String getFoods(Integer foodID){
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
        }

        query += "GROUP BY alimentos.id, alimentos.nombre, usuarios.usuario";

        return query;
    }
}
