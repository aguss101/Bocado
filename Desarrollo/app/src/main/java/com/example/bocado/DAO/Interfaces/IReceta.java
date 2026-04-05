package com.example.bocado.DAO.Interfaces;

import io.flutter.plugin.common.MethodChannel;
import com.example.bocado.entidades.Receta;
import org.json.JSONObject;
import java.util.Map;
public interface IReceta {
    void crear(Map<String, Object> args, MethodChannel.Result result);

}