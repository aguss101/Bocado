package com.example.bocado.entidades;

public class Alimento_Nutriente
{
    private Alimento alimento;
    private Nutriente nutriente;
    private int valor100gr;

    public Alimento_Nutriente(Alimento alimento, Nutriente nutriente, int valor100gr) {
        this.alimento = alimento;
        this.nutriente = nutriente;
        this.valor100gr = valor100gr;
    }

    public Alimento_Nutriente() {
    }

    public Alimento getAlimento() {
        return alimento;
    }

    public void setAlimento(Alimento alimento) {
        this.alimento = alimento;
    }

    public Nutriente getNutriente() {
        return nutriente;
    }

    public void setNutriente(Nutriente nutriente) {
        this.nutriente = nutriente;
    }

    public int getValor100gr() {
        return valor100gr;
    }

    public void setValor100gr(int valor100gr) {
        this.valor100gr = valor100gr;
    }
}
