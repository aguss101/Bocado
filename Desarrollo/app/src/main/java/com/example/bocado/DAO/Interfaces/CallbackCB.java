package com.example.bocado.DAO.Interfaces;

public interface CallbackCB {
    void onSuccess(String result);
    void onError(String code, String message, Object details);
}