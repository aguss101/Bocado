package com.example.bocado.DAO;

public interface LoginCallback {
    void onSuccess(String result);
    void onError(String code, String message, Object details);
}