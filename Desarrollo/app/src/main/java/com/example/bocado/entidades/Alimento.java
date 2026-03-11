package com.example.bocado.entidades;

import java.util.List;

public class Alimento
{
    private int id;
    private String nombre;
    private Usuario usuario;
    private Medida medida;
    private List<Alimento_Nutriente> listaNutrientes; ///Capaz podemos hacer un DTO aparte de Alimento?

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

    public Usuario getUsuario() {
        return usuario;
    }

    public void setUsuario(Usuario usuario) {
        this.usuario = usuario;
    }

    public Medida getMedida() {
        return medida;
    }

    public void setMedida(Medida medida) {
        this.medida = medida;
    }

    public List<Alimento_Nutriente> getListaNutrientes() {
        return listaNutrientes;
    }

    public void setListaNutrientes(List<Alimento_Nutriente> listaNutrientes) {
        this.listaNutrientes = listaNutrientes;
    }
}
