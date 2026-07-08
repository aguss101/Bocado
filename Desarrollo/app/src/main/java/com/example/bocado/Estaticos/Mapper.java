package com.example.bocado.Estaticos;

import com.example.bocado.Entidades.Usuario;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;
import java.sql.Timestamp;
import java.util.List;
import java.util.Map;
public class Mapper {

    public static Usuario jsonToUsuario(JSONObject json) throws JSONException {
        Usuario u = new Usuario();

        u.setCuenta(String.valueOf(json.optInt("id_cuenta", 1)));
        u.setNacion(String.valueOf(json.optInt("id_nacion", 0)));
        u.setGenero(String.valueOf(json.optInt("id_genero", 0)));

        u.setNombre(json.optString("nombre", ""));
        u.setApellido(json.optString("apellido", ""));
        u.setCorreo(json.optString("correo", ""));
        u.setUsuario(json.optString("usuario", ""));
        u.setContrasena(json.optString("contrasena", ""));

        u.setFecha_Nacimiento(json.optString("fecha_nacimiento", null));
        u.setFecha_Creacion(parseTimestampSupabase(json.optString("fecha_creacion", null)));
        u.setFecha_Acceso(parseTimestampSupabase(json.optString("fecha_acceso", null)));

        u.setActivo(json.optBoolean("activo", true));
        u.setVisibilidad(json.optBoolean("visibilidad", true));

        u.setBio(json.optString("bio", ""));

        u.setFoto(json.isNull("foto") ? null : json.optString("foto", null));
        u.setBanner(json.isNull("banner") ? null : json.optString("banner", null));

        return u;
    }

    public static JSONObject usuarioToJson(Usuario u) throws JSONException {
        JSONObject data = new JSONObject();

        data.put("usuario", u.getUsuario());
        data.put("correo", u.getCorreo());
        data.put("contrasena", u.getContrasena());
        data.put("nombre", u.getNombre());
        data.put("apellido", u.getApellido());
        data.put("id_nacion", Integer.parseInt(u.getNacion()));
        data.put("id_genero", Integer.parseInt(u.getGenero()));
        data.put("fecha_nacimiento", u.getFecha_Nacimiento());
        data.put("bio", u.getBio());

        return data;
    }

    public static JSONObject usuarioToClientJson(Usuario u) throws JSONException {
        JSONObject json = new JSONObject();

        json.put("id", u.getId());
        json.put("id_cuenta", Integer.parseInt(u.getCuenta()));
        json.put("usuario", u.getUsuario());
        json.put("foto",   u.getFoto()   != null ? u.getFoto()   : JSONObject.NULL);
        json.put("banner", u.getBanner() != null ? u.getBanner() : JSONObject.NULL);
        json.put("bio", u.getBio() != null ? u.getBio() : "");

        return json;
    }

    public static JSONObject usuarioToEditJson(Usuario u) throws JSONException {
        JSONObject json = new JSONObject();
        json.put("usuario", u.getUsuario());
        json.put("correo", u.getCorreo());
        json.put("id_genero", Integer.parseInt(u.getGenero()));
        json.put("visibilidad", u.isVisibilidad());
        json.put("bio", u.getBio());
        return json;
    }

    private static Timestamp parseTimestampSupabase(String raw) {
        if (raw == null || raw.isEmpty()) return null;
        try {
            String limpio = raw.replace("T", " ").replace("Z", "");
            if (limpio.length() > 19) {
                limpio = limpio.substring(0, 19);
            }
            return Timestamp.valueOf(limpio);
        } catch (Exception e) {
            return null;
        }
    }

    public static JSONObject recetaToJson(Map<String, Object> args) throws JSONException {
        JSONObject recetaJson = new JSONObject();
        recetaJson.put("id_usuario", args.get("id_usuario"));
        recetaJson.put("nombre", args.get("nombre"));
        recetaJson.put("calorias_totales", args.get("calorias_totales"));
        recetaJson.put("porciones", args.get("porciones"));
        recetaJson.put("porciones_peso", args.get("porciones_peso"));
        recetaJson.put("id_dificultad", args.get("id_dificultad"));
        recetaJson.put("precio", args.get("precio"));
        recetaJson.put("visibilidad", args.get("visibilidad"));
        recetaJson.put("es_borrador", args.get("es_borrador"));
        recetaJson.put("tiempo_coccion", args.get("tiempo_coccion"));
        recetaJson.put("breve_descripcion", args.get("breve_descripcion"));

        if (args.containsKey("fotos")) {
            List<String> listaFotos = (List<String>) args.get("fotos");
            recetaJson.put("foto", String.join("|", listaFotos));
        }
        if (args.containsKey("instrucciones")) {
            List<String> listaPasos = (List<String>) args.get("instrucciones");
            recetaJson.put("instrucciones", String.join("|", listaPasos));
        }
        if (args.containsKey("tags_ids")) {
            recetaJson.put("tags_ids", new JSONArray((List<?>) args.get("tags_ids")));
        }
        if (args.containsKey("ingredientes")) {
            Object ingredientesObj = args.get("ingredientes");
            if (ingredientesObj instanceof List) {
                recetaJson.put("ingredientes", new JSONArray((List<?>) ingredientesObj));
            } else {
                recetaJson.put("ingredientes", ingredientesObj);
            }
        }
        return recetaJson;
    }
}