package com.setli.app;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.widget.ImageButton;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.appcompat.widget.AppCompatButton;
import androidx.core.view.ViewCompat;
import androidx.viewpager2.widget.ViewPager2;
import com.getcapacitor.BridgeActivity;
import java.util.Arrays;
import java.util.List;

public class MainActivity extends BridgeActivity {

    public static final String PREFS_NAME = "SetliPrefs";
    public static final String KEY_COMPLETED_ONBOARDING = "hasCompletedOnboarding";

    private View onboardingContainer;

    public static void resetOnboardingStatus(Context context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_COMPLETED_ONBOARDING)
            .apply();
    }

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

        setupOnboardingIfNeeded();

        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                if (onboardingContainer != null && onboardingContainer.getVisibility() == View.VISIBLE) {
                    ViewPager2 vp = onboardingContainer.findViewById(R.id.viewPager);
                    if (vp != null && vp.getCurrentItem() > 0) {
                        vp.setCurrentItem(vp.getCurrentItem() - 1, true);
                        return;
                    }
                }

                WebView webView = getBridge() != null ? getBridge().getWebView() : null;

                if (webView != null && webView.canGoBack()) {
                    webView.goBack();
                } else {
                    setEnabled(false);
                    getOnBackPressedDispatcher().onBackPressed();
                }
            }
        });
    }

    private void setupOnboardingIfNeeded() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        boolean hasCompleted = prefs.getBoolean(KEY_COMPLETED_ONBOARDING, false);
        if (hasCompleted) {
            return;
        }

        ViewGroup root = findViewById(android.R.id.content);
        if (root == null) {
            return;
        }

        onboardingContainer = getLayoutInflater().inflate(R.layout.view_onboarding, root, false);
        root.addView(onboardingContainer, new ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ));

        ViewPager2 viewPager = onboardingContainer.findViewById(R.id.viewPager);
        ImageButton btnLeftArrow = onboardingContainer.findViewById(R.id.btnLeftArrow);
        ImageButton btnRightArrow = onboardingContainer.findViewById(R.id.btnRightArrow);
        AppCompatButton btnGetStarted = onboardingContainer.findViewById(R.id.btnGetStarted);
        View dot0 = onboardingContainer.findViewById(R.id.dot0);
        View dot1 = onboardingContainer.findViewById(R.id.dot1);
        View dot2 = onboardingContainer.findViewById(R.id.dot2);

        List<OnboardingSlide> slides = Arrays.asList(
            new OnboardingSlide(
                R.drawable.app_logo,
                "Welcome to Setli",
                "Streamline your property maintenance, settlements, and updates all in one place."
            ),
            new OnboardingSlide(
                R.drawable.app_logo,
                "Track & Manage Requests",
                "Effortlessly submit maintenance issues, upload documentation, and receive real-time updates."
            ),
            new OnboardingSlide(
                R.drawable.app_logo,
                "Seamless Settlement Experience",
                "Connect directly with property managers and enjoy a stress-free transition."
            )
        );

        viewPager.setAdapter(new OnboardingAdapter(slides));

        viewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                super.onPageSelected(position);
                updateControls(position, true, btnLeftArrow, btnRightArrow, btnGetStarted, dot0, dot1, dot2);
            }
        });

        // Initialize state for Index 0
        updateControls(0, false, btnLeftArrow, btnRightArrow, btnGetStarted, dot0, dot1, dot2);

        btnLeftArrow.setOnClickListener(v -> {
            int current = viewPager.getCurrentItem();
            if (current > 0) {
                viewPager.setCurrentItem(current - 1, true);
            }
        });

        btnRightArrow.setOnClickListener(v -> {
            int current = viewPager.getCurrentItem();
            if (current < slides.size() - 1) {
                viewPager.setCurrentItem(current + 1, true);
            }
        });

        btnGetStarted.setOnClickListener(v -> {
            getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_COMPLETED_ONBOARDING, true)
                .apply();

            onboardingContainer.animate()
                .alpha(0f)
                .setDuration(300)
                .withEndAction(() -> {
                    if (root != null && onboardingContainer != null) {
                        root.removeView(onboardingContainer);
                    }
                    onboardingContainer = null;
                })
                .start();
        });
    }

    private void updateControls(
        int index,
        boolean animate,
        ImageButton btnLeft,
        ImageButton btnRight,
        AppCompatButton btnGetStarted,
        View dot0,
        View dot1,
        View dot2
    ) {
        // Update indicator dots
        dot0.setBackgroundResource(index == 0 ? R.drawable.bg_dot_active : R.drawable.bg_dot_inactive);
        dot1.setBackgroundResource(index == 1 ? R.drawable.bg_dot_active : R.drawable.bg_dot_inactive);
        dot2.setBackgroundResource(index == 2 ? R.drawable.bg_dot_active : R.drawable.bg_dot_inactive);

        // Index 0: only bottom-right arrow
        // Index 1: bottom-left arrow and right-side arrow
        // Index 2: bottom-left arrow and 'Get Started' button
        boolean showLeft = (index > 0);
        boolean showRight = (index < 2);
        boolean showGetStarted = (index == 2);

        if (animate) {
            // Left Button
            if (showLeft) {
                btnLeft.setVisibility(View.VISIBLE);
                btnLeft.animate().alpha(1f).setDuration(200).start();
            } else {
                btnLeft.animate().alpha(0f).setDuration(200).withEndAction(() -> btnLeft.setVisibility(View.INVISIBLE)).start();
            }

            // Right Arrow Button
            if (showRight) {
                btnRight.setVisibility(View.VISIBLE);
                btnRight.animate().alpha(1f).setDuration(200).start();
            } else {
                btnRight.animate().alpha(0f).setDuration(200).withEndAction(() -> btnRight.setVisibility(View.GONE)).start();
            }

            // Get Started Button
            if (showGetStarted) {
                btnGetStarted.setVisibility(View.VISIBLE);
                btnGetStarted.animate().alpha(1f).setDuration(200).start();
            } else {
                btnGetStarted.animate().alpha(0f).setDuration(200).withEndAction(() -> btnGetStarted.setVisibility(View.GONE)).start();
            }
        } else {
            btnLeft.setAlpha(showLeft ? 1f : 0f);
            btnLeft.setVisibility(showLeft ? View.VISIBLE : View.INVISIBLE);

            btnRight.setAlpha(showRight ? 1f : 0f);
            btnRight.setVisibility(showRight ? View.VISIBLE : View.GONE);

            btnGetStarted.setAlpha(showGetStarted ? 1f : 0f);
            btnGetStarted.setVisibility(showGetStarted ? View.VISIBLE : View.GONE);
        }
    }
}
