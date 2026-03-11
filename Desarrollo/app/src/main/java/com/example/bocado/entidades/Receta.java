package com.example.bocado.entidades;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Receta
{
    private int id;
    private int id_Usuario;
    private String nombre;
    private byte[] foto;
    private BigDecimal calorias_Totales;
    private int porciones;
    private BigDecimal porciones_Peso;
    private String instrucciones;
    private Timestamp fecha_Creacion;
    private boolean visibilidad;
    private boolean activo;
    private BigDecimal precio;
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getId_Usuario() {
        return id_Usuario;
    }

    public void setId_Usuario(int id_Usuario) {
        this.id_Usuario = id_Usuario;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public byte[] getFoto() {
        return foto;
    }

    public void setFoto(byte[] foto) {
        this.foto = foto;
    }

    public BigDecimal getCalorias_Totales() {
        return calorias_Totales;
    }

    public void setCalorias_Totales(BigDecimal calorias_Totales) {
        this.calorias_Totales = calorias_Totales;
    }

    public int getPorciones() {
        return porciones;
    }

    public void setPorciones(int porciones) {
        this.porciones = porciones;
    }

    public BigDecimal getPorciones_Peso() {
        return porciones_Peso;
    }

    public void setPorciones_Peso(BigDecimal porciones_Peso) {
        this.porciones_Peso = porciones_Peso;
    }

    public String getInstrucciones() {
        return instrucciones;
    }

    public void setInstrucciones(String instrucciones) {
        this.instrucciones = instrucciones;
    }

    public Timestamp getFecha_Creacion() {
        return fecha_Creacion;
    }

    public void setFecha_Creacion(Timestamp fecha_Creacion) {
        this.fecha_Creacion = fecha_Creacion;
    }

    public boolean isVisibilidad() {
        return visibilidad;
    }

    public void setVisibilidad(boolean visibilidad) {
        this.visibilidad = visibilidad;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }

    public BigDecimal getPrecio() {
        return precio;
    }

    public void setPrecio(BigDecimal precio) {
        this.precio = precio;
    }
}
