package com.example.bocado.DAO.Interfaces;

import io.flutter.plugin.common.MethodChannel;

import java.util.Map;
public interface IReceta {
    void create(Map<String, Object> args, MethodChannel.Result result);
    void getById(int idReceta, MethodChannel.Result result);

}