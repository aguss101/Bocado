package com.example.bocado.Estaticos;

import com.example.bocado.entidades.Usuario;
import org.json.JSONObject;
import org.json.JSONException;

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
}