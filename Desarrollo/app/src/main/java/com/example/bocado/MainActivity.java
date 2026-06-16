package com.example.bocado;

import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.splashscreen.SplashScreen;

import android.net.Uri;

import com.example.bocado.Channels.AccessChannel;
import com.example.bocado.Channels.InteractionsChannel;
import com.example.bocado.Channels.RecetasChannel;
import com.example.bocado.Channels.ImagesChannel;
import com.example.bocado.Channels.NavigationChannel;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;

public class MainActivity extends FlutterActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();

        // Extraer deep link si la app fue abierta desde bocado://perfil/{id}
        String deepLink = null;
        Uri data = getIntent().getData();
        if (data != null && "bocado".equals(data.getScheme())) {
            deepLink = data.toString();
        }

        new AccessChannel(this, messenger);
        new RecetasChannel(this, messenger);
        new ImagesChannel(this, messenger);
        new InteractionsChannel(this, messenger);
        new NavigationChannel(messenger, deepLink);
    }
}
