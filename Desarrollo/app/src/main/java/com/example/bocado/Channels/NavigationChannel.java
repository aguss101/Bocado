package com.example.bocado.Channels;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

public class NavigationChannel {

    private static final String CHANNEL = "com.example.bocado/navigation";
    private final MethodChannel channel;

    public NavigationChannel(BinaryMessenger messenger, String initialDeepLink) {
        this.channel = new MethodChannel(messenger, CHANNEL);
        channel.setMethodCallHandler((call, result) -> {
            if ("getInitialDeepLink".equals(call.method)) {
                result.success(initialDeepLink);
            } else {
                result.notImplemented();
            }
        });
    }

    public void onNewDeepLink(String deepLink) {
        channel.invokeMethod("onDeepLink", deepLink);
    }
}
