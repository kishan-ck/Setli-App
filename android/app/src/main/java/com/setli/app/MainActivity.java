package com.setli.app;

import android.graphics.Color;
import android.os.Bundle;
import android.webkit.WebView;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.view.ViewCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Force application to always use Light Mode
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);
        // Handle system bar backgrounds
        ViewCompat.setOnApplyWindowInsetsListener(getWindow().getDecorView(), (view, windowInsets) -> {
            // Keep the system bar areas white
            view.setBackgroundColor(Color.WHITE);

            return windowInsets;
        });
        getOnBackPressedDispatcher().addCallback(this, new androidx.activity.OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {

                WebView webView = getBridge().getWebView();

                if (webView.canGoBack()) {
                    webView.goBack();
                } else {
                    setEnabled(false);
                    getOnBackPressedDispatcher().onBackPressed();
                }
            }
        });
    }
}
