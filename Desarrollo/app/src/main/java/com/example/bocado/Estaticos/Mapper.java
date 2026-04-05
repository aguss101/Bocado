package com.example.bocado.Estaticos;

import com.example.bocado.entidades.Usuario;
import com.example.bocado.entidades.Receta;
import org.json.JSONObject;
import org.json.JSONException;
import java.math.BigDecimal;
import java.sql.Timestamp;
public class Mapper {

    // RECIBE DATOS de Supa
    // Reemplaza a getUsuario y setUsuario
    public static Usuario jsonToUsuario(JSONObject json) throws JSONException {
        Usuario u = new Usuario();

        u.setId(json.optInt("id", 0));
        u.setNombre(json.optString("nombre", ""));
        u.setApellido(json.optString("apellido", ""));
        u.setCorreo(json.optString("correo", ""));
        u.setUsuario(json.optString("usuario", ""));
        u.setContrasena(json.optString("contrasena", ""));
        u.setActivo(json.optBoolean("activo", true));
        u.setVisibilidad(json.optBoolean("visibilidad", true));

        return u;
    }

    // ENVIAMOS DATOS a Supa
    // Reemplaza a createUsuario y modUsuario
    public static JSONObject usuarioToJson(Usuario u) throws JSONException {
        JSONObject json = new JSONObject();

        json.put("nombre", u.getNombre());
        json.put("apellido", u.getApellido());
        json.put("correo", u.getCorreo());
        json.put("usuario", u.getUsuario());
        json.put("contrasena", u.getContrasena());

        // Se envian los IDs foráneos si existen
        if (u.getNacion() != null) json.put("id_nacion", Integer.parseInt(u.getNacion()));
        if (u.getGenero() != null) json.put("id_genero", Integer.parseInt(u.getGenero()));

        return json;
    }

    //____________________________________________
    public static Receta jsonToReceta(JSONObject json) throws JSONException {
        Receta r = new Receta();

        r.setId(json.optInt("id", 0));
        r.setId_Usuario(json.optInt("id_usuario", 0)); // Respetando tu get/set
        r.setNombre(json.optString("nombre", ""));
        r.setInstrucciones(json.optString("instrucciones", ""));
        r.setPorciones(json.optInt("porciones", 1));

        r.setCalorias_Totales(BigDecimal.valueOf(json.optDouble("calorias_totales", 0.0)));
        r.setPorciones_Peso(BigDecimal.valueOf(json.optDouble("porciones_peso", 0.0)));
        r.setPrecio(BigDecimal.valueOf(json.optDouble("precio", 0.0)));

        r.setActivo(json.optBoolean("activo", true));
        r.setVisibilidad(json.optBoolean("visibilidad", true));

        String fechaSupa = json.optString("fecha_creacion", null);
        if (fechaSupa != null && !fechaSupa.isEmpty()) {
            try {
                String cleanDate = fechaSupa.replace("T", " ").replace("Z", "");
                if (cleanDate.length() > 19) {
                    cleanDate = cleanDate.substring(0, 19);
                }
                r.setFecha_Creacion(Timestamp.valueOf(cleanDate));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        /* mapear la foto desde Base64:
          String fotoB64 = json.optString("foto", null);
          if(fotoB64 != null) r.setFoto(android.util.Base64.decode(fotoB64, android.util.Base64.DEFAULT));
         */

        return r;
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