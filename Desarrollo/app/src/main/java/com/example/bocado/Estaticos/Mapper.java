package com.example.bocado.Estaticos;

import com.example.bocado.Entidades.Usuario;
import com.example.bocado.Entidades.Receta;
import org.json.JSONObject;
import org.json.JSONException;
import java.math.BigDecimal;
import java.sql.Timestamp;
public class Mapper {

    // RECIBE DATOS de Supa
    public static Usuario jsonToUsuario(JSONObject json) throws JSONException {
        Usuario u = new Usuario();

        u.setId(json.optInt("id", 0));
        u.setCuenta(String.valueOf(json.optInt("id_cuenta", 1)));
        u.setNacion(String.valueOf(json.optInt("id_nacion", 0)));
        u.setGenero(String.valueOf(json.optInt("id_genero", 0)));

        u.setNombre(json.optString("nombre", ""));
        u.setApellido(json.optString("apellido", ""));
        u.setCorreo(json.optString("correo", ""));
        u.setUsuario(json.optString("usuario", ""));
        u.setContrasena(json.optString("contrasena", ""));

        u.setFecha_Nacimiento(json.optString("fecha_nacimiento", null)); // ISO crudo (String)
        u.setFecha_Creacion(parseTimestampSupabase(json.optString("fecha_creacion", null)));
        u.setFecha_Acceso(parseTimestampSupabase(json.optString("fecha_acceso", null)));

        u.setActivo(json.optBoolean("activo", true));
        u.setVisibilidad(json.optBoolean("visibilidad", true));

        u.setFoto(json.isNull("foto") ? null : json.optString("foto", null));
        u.setBanner(json.isNull("banner") ? null : json.optString("banner", null));

        return u;
    }

    // ENVIAMOS DATOS a Supa
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

        return data;
    }

    // ENVIAMOS al cliente Flutter — solo lo que la UI necesita, SIN contrasena.
    public static JSONObject usuarioToClientJson(Usuario u) throws JSONException {
        JSONObject json = new JSONObject();

        json.put("id", u.getId());
        json.put("id_cuenta", Integer.parseInt(u.getCuenta()));
        json.put("usuario", u.getUsuario());
        // Mismas claves que espera usuario_Logged.fromJson (foto/banner = URL o null).
        json.put("foto",   u.getFoto()   != null ? u.getFoto()   : JSONObject.NULL);
        json.put("banner", u.getBanner() != null ? u.getBanner() : JSONObject.NULL);

        return json;
    }

    // ENVIAMOS al cliente los campos EDITABLES del propio perfil (incluye correo).
    // Separado de usuarioToClientJson para NO filtrar el correo al ver perfiles ajenos.
    public static JSONObject usuarioToEditJson(Usuario u) throws JSONException {
        JSONObject json = new JSONObject();
        json.put("usuario", u.getUsuario());
        json.put("correo", u.getCorreo());
        json.put("id_genero", Integer.parseInt(u.getGenero()));
        json.put("visibilidad", u.isVisibilidad());
        return json;
    }
    
    public static Receta jsonToReceta(JSONObject json) throws JSONException {
        Receta r = new Receta();

        r.setId(json.optInt("id", 0));
        r.setId_Usuario(json.optInt("id_usuario", 0));
        r.setNombre(json.optString("nombre", ""));
        r.setInstrucciones(json.optString("instrucciones", ""));
        r.setPorciones(json.optInt("porciones", 1));

        r.setCalorias_Totales(BigDecimal.valueOf(json.optDouble("calorias_totales", 0.0)));
        r.setPorciones_Peso(BigDecimal.valueOf(json.optDouble("porciones_peso", 0.0)));
        r.setPrecio(BigDecimal.valueOf(json.optDouble("precio", 0.0)));

        r.setActivo(json.optBoolean("activo", true));
        r.setVisibilidad(json.optBoolean("visibilidad", true));

        r.setFecha_Creacion(parseTimestampSupabase(json.optString("fecha_creacion", null)));

        return r;
    }


     // Convierte un timestamp ISO de Supabase (ej: "2024-01-15T10:30:00.123Z")
     // a java.sql.Timestamp. Devuelve null si el texto es vacío o no parsea,
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

    // ENVIAMOS a Supabase
    public static JSONObject recetaToJson(Receta r) throws JSONException {
        JSONObject json = new JSONObject();

        json.put("id_usuario", r.getId_Usuario());
        json.put("nombre", r.getNombre());
        json.put("instrucciones", r.getInstrucciones());
        json.put("porciones", r.getPorciones());

        if (r.getCalorias_Totales() != null) {
            json.put("calorias_totales", r.getCalorias_Totales().doubleValue());
        }
        if (r.getPorciones_Peso() != null) {
            json.put("porciones_peso", r.getPorciones_Peso().doubleValue());
        }
        if (r.getPrecio() != null) {
            json.put("precio", r.getPrecio().doubleValue());
        }

        json.put("activo", r.isActivo());
        json.put("visibilidad", r.isVisibilidad());

        return json;
    }
}