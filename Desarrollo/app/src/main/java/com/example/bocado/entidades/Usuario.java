package com.example.bocado.entidades;

import java.sql.Timestamp;
public class Usuario
{
    private int id;
    private int id_Cuenta;
    private int id_Nacion;
    private int id_Genero;
    private String nombre;
    private String apellido;
    private String correo;
    private String usuario;
    private String contrasena;
    private Timestamp fecha_Nacimiento;
    private Timestamp fecha_Creacion;
    private Timestamp fecha_Acceso;
    private boolean activo;
    private boolean visibilidad;
    private byte[] foto;
    private byte[] banner;

    public Usuario() {
    }

    public Usuario(int id, int id_Cuenta, int id_Nacion, int id_Genero, String nombre, String apellido, String correo, String usuario, String contrasena, Timestamp fecha_Nacimiento, Timestamp fecha_Creacion, Timestamp fecha_Acceso, boolean activo, boolean visibilidad, byte[] foto, byte[] banner) {
        this.id = id;
        this.id_Cuenta = id_Cuenta;
        this.id_Nacion = id_Nacion;
        this.id_Genero = id_Genero;
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

    public int getId_Cuenta() {
        return id_Cuenta;
    }

    public void setId_Cuenta(int id_Cuenta) {
        this.id_Cuenta = id_Cuenta;
    }

    public int getId_Nacion() {
        return id_Nacion;
    }

    public void setId_Nacion(int id_Nacion) {
        this.id_Nacion = id_Nacion;
    }

    public int getId_Genero() {
        return id_Genero;
    }

    public void setId_Genero(int id_Genero) {
        this.id_Genero = id_Genero;
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

    public String getContraseña() {
        return contrasena;
    }

    public void setContrasena(String contraseña) {
        this.contrasena = contraseña;
    }

    public Timestamp getFecha_Nacimiento() {
        return fecha_Nacimiento;
    }

    public void setFecha_Nacimiento(Timestamp fecha_Nacimiento) {
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

    public byte[] getFoto() {
        return foto;
    }

    public void setFoto(byte[] foto) {
        this.foto = foto;
    }

    public byte[] getBanner() {
        return banner;
    }

    public void setBanner(byte[] banner) {
        this.banner = banner;
    }
}
