package com.example.bocado.Estaticos;
public class Query {
    public static String getUsers(Integer userID){
        String query = "SELECT " +
                "\"Usuarios\".id as id, " +
                "\"Cuentas\".nombre as cuenta, " +
                "\"Naciones\".nombre as pais, " +
                "\"Generos\".nombre as genero, " +
                "\"Usuarios\".nombre, \"Usuarios\".apellido, " +
                "\"Usuarios\".correo, \"Usuarios\".usuario, \"Usuarios\".contrasena, " +
                "\"Usuarios\".fecha_nacimiento, \"Usuarios\".fecha_creacion, \"Usuarios\".fecha_acceso, " +
                "\"Usuarios\".activo, \"Usuarios\".visibilidad, \"Usuarios\".foto, \"Usuarios\".banner " +
                "FROM \"Usuarios\" " +
                "JOIN \"Cuentas\" ON \"Usuarios\".id_cuenta = \"Cuentas\".id " +
                "JOIN \"Naciones\" ON \"Usuarios\".id_nacion = \"Naciones\".id " +
                "JOIN \"Generos\" ON \"Usuarios\".id_genero = \"Generos\".id";
        if(userID != null){
            query += " WHERE \"Usuarios\".id = " + userID;
        }
        return query;
    }
    public static String getFoods(Integer foodID){
        String query = "SELECT " +
                "\"Alimentos\".id AS id, " +
                "\"Alimentos\".nombre, " +
                "\"Usuarios\".usuario AS usuario, " +

                "MAX(CASE WHEN \"Nutrientes\".nombre = 'Proteinas' THEN \"Alimentos_Nutrientes\".valor100gr END) AS proteinas, " +
                "MAX(CASE WHEN \"Nutrientes\".nombre = 'Carbohidratos' THEN \"Alimentos_Nutrientes\".valor100gr END) AS carbohidratos, " +
                "MAX(CASE WHEN \"Nutrientes\".nombre = 'Grasas' THEN \"Alimentos_Nutrientes\".valor100gr END) AS grasas, " +
                "MAX(CASE WHEN \"Nutrientes\".nombre = 'Vitamina C' THEN \"Alimentos_Nutrientes\".valor100gr END) AS vitamina_c " +

                "FROM \"Alimentos\" " +
                "LEFT JOIN \"Usuarios\" ON \"Usuarios\".id = \"Alimentos\".id_usuario " +
                "LEFT JOIN \"Alimentos_Nutrientes\" ON \"Alimentos_Nutrientes\".id_alimento = \"Alimentos\".id " +
                "LEFT JOIN \"Nutrientes\" ON \"Nutrientes\".id = \"Alimentos_Nutrientes\".id_nutriente ";

        if(foodID != null){
            query += "WHERE \"Alimentos\".id = " + foodID + " ";
        }

        query += "GROUP BY \"Alimentos\".id, \"Alimentos\".nombre, \"Usuarios\".usuario";

        return query;
    }
}
