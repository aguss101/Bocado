package com.example.bocado.entidades;

public class Nutriente
{
    private int id;
    private String nombre;
    private boolean esMacro;
    private Medida medida;

    public Nutriente(int id, String nombre, boolean esMacro, Medida medida) {
        this.id = id;
        this.nombre = nombre;
        this.esMacro = esMacro;
        this.medida = medida;
    }

    public Nutriente() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public boolean isEsMacro() {
        return esMacro;
    }

    public void setEsMacro(boolean esMacro) {
        this.esMacro = esMacro;
    }

    public Medida getMedida() {
        return medida;
    }

    public void setMedida(Medida medida) {
        this.medida = medida;
    }
}
