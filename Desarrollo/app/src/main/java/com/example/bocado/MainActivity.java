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

        // Extraer deep link de perfil o receta:
        //   bocado://{perfil|receta}/{slug} o https://links.bocado.tech/{perfil|receta}/{slug}
        String deepLink = null;
        Uri data = getIntent().getData();
        if (data != null) {
            boolean esCustom = "bocado".equals(data.getScheme());
            boolean esHttps = "https".equals(data.getScheme()) && "links.bocado.tech".equals(data.getHost());
            if (esCustom || esHttps) {
                deepLink = data.toString();
            }
        }

        new AccessChannel(this, messenger);
        new RecetasChannel(this, messenger);
        new ImagesChannel(this, messenger);
        new InteractionsChannel(this, messenger);
        new NavigationChannel(messenger, deepLink);
    }
}
