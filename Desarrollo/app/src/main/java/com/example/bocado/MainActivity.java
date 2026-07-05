package com.example.bocado;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.splashscreen.SplashScreen;

import android.net.Uri;

import com.example.bocado.Channels.*;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;

public class MainActivity extends FlutterActivity {

    private NavigationChannel navigationChannel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();

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
        new AppChannel(this, messenger);
        new AccountChannel(this, messenger);
        navigationChannel = new NavigationChannel(messenger, deepLink);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (navigationChannel == null) return;
        Uri data = intent.getData();
        if (data == null) return;
        boolean esCustom = "bocado".equals(data.getScheme());
        boolean esHttps = "https".equals(data.getScheme()) && "links.bocado.tech".equals(data.getHost());
        if (esCustom || esHttps) {
            navigationChannel.onNewDeepLink(data.toString());
        }
    }
}
