package com.example.bocado.Channels;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

public class NavigationChannel {

    private static final String CHANNEL = "com.example.bocado/navigation";

    public NavigationChannel(BinaryMessenger messenger, String initialDeepLink) {
        new MethodChannel(messenger, CHANNEL).setMethodCallHandler((call, result) -> {
            if ("getInitialDeepLink".equals(call.method)) {
                result.success(initialDeepLink); // null si no hubo deep link
            } else {
                result.notImplemented();
            }
        });
    }
}
