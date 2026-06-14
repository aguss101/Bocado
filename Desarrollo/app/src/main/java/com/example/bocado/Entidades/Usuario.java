package com.example.bocado.Entidades;

import java.sql.Timestamp;
public class Usuario
{
    private int id;
    private String cuenta;
    private String nacion;
    private String genero;
    private String nombre;
    private String apellido;
    private String correo;
    private String usuario;
    private String contrasena;
    private String fecha_Nacimiento;
    private Timestamp fecha_Creacion;
    private Timestamp fecha_Acceso;
    private boolean activo;
    private boolean visibilidad;
    private String foto;
    private String banner;

    public Usuario() {
    }

    public Usuario(int id, String cuenta, String nacion, String genero, String nombre, String apellido, String correo, String usuario, String contrasena, String fecha_Nacimiento, Timestamp fecha_Creacion, Timestamp fecha_Acceso, boolean activo, boolean visibilidad, String foto, String banner) {
        this.id = id;
        this.cuenta = cuenta;
        this.nacion = nacion;
        this.genero = genero;
        this.nombre = nombre;
        this.apellido = apellido;
        this.correo = correo;
        this.usuario = usuario;
        this.contrasena = contrasena;
        this.fecha_Nacimiento = fecha_Nacimiento;
        this.fecha_Creacion = fecha_Creacion;
        this.fecha_Acceso = fecha_Acceso;
        this.activo = activo;
        this.visibilidad = visibilidad;
        this.foto = foto;
        this.banner = banner;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getCuenta() {
        return cuenta;
    }

    public void setCuenta(String cuenta) {
        this.cuenta = cuenta;
    }

    public String getNacion() {
        return nacion;
    }

    public void setNacion(String nacion) {
        this.nacion = nacion;
    }

    public String getGenero() {
        return genero;
    }

    public void setGenero(String genero) {
        this.genero = genero;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getApellido() {
        return apellido;
    }

    public void setApellido(String apellido) {
        this.apellido = apellido;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }

    public String getUsuario() {
        return usuario;
    }

    public void setUsuario(String usuario) {
        this.usuario = usuario;
    }

    public String getContrasena() {
        return contrasena;
    }

    public void setContrasena(String contrasena) {
        this.contrasena = contrasena;
    }

    public String getFecha_Nacimiento() {
        return fecha_Nacimiento;
    }

    public void setFecha_Nacimiento(String fecha_Nacimiento) {
        this.fecha_Nacimiento = fecha_Nacimiento;
    }

    public Timestamp getFecha_Creacion() {
        return fecha_Creacion;
    }

    public void setFecha_Creacion(Timestamp fecha_Creacion) {
        this.fecha_Creacion = fecha_Creacion;
    }

    public Timestamp getFecha_Acceso() {
        return fecha_Acceso;
    }

    public void setFecha_Acceso(Timestamp fecha_Acceso) {
        this.fecha_Acceso = fecha_Acceso;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }

    public boolean isVisibilidad() {
        return visibilidad;
    }

    public void setVisibilidad(boolean visibilidad) {
        this.visibilidad = visibilidad;
    }

    public String getFoto() {
        return foto;
    }

    public void setFoto(String foto) {
        this.foto = foto;
    }

    public String getBanner() {
        return banner;
    }

    public void setBanner(String banner) {
        this.banner = banner;
    }

}
