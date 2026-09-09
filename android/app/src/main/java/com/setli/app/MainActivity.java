package com.setli.app;

import android.app.AlertDialog;
import android.app.DownloadManager;
import android.content.ContentValues;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.URLUtil;
import android.webkit.WebView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.appcompat.widget.AppCompatButton;
import androidx.core.view.ViewCompat;
import androidx.viewpager2.widget.ViewPager2;
import com.getcapacitor.BridgeActivity;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
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
                    showExitConfirmationDialog();
//                    setEnabled(false);
//                    getOnBackPressedDispatcher().onBackPressed();
                }
            }
        });

        WebView webView = getBridge().getWebView();

        webView.setDownloadListener((url, userAgent, contentDisposition, mimeType, contentLength) -> {

            // ==============================
            // BASE64 IMAGE DOWNLOAD
            // ==============================
            if (url != null && url.startsWith("data:image/")) {
                try {
                    // Example:
                    // data:image/png;base64,iVBORw0KGgoAAAANS...

                    String[] parts = url.split(",", 2);

                    if (parts.length != 2) {
                        Toast.makeText(this, "Invalid image data", Toast.LENGTH_SHORT).show();
                        return;
                    }

                    // Get MIME type
                    String header = parts[0];
                    String base64Data = parts[1];
                    String imageType = "png";

                    if (header.contains("image/jpeg")) {
                        imageType = "jpg";
                    } else if (header.contains("image/jpg")) {
                        imageType = "jpg";
                    } else if (header.contains("image/webp")) {
                        imageType = "webp";
                    } else if (header.contains("image/gif")) {
                        imageType = "gif";
                    }

                    // Decode Base64
                    byte[] imageBytes = Base64.decode(base64Data, Base64.DEFAULT);

                    String fileName = "Setli_" + System.currentTimeMillis() + "." + imageType;

                    // ==============================
                    // ANDROID 10+
                    // ==============================
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

                        ContentValues values = new ContentValues();
                        values.put(MediaStore.Downloads.DISPLAY_NAME, fileName);
                        values.put(MediaStore.Downloads.MIME_TYPE, "image/" + imageType);
                        values.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Setli");
                        values.put(MediaStore.Downloads.IS_PENDING, 1);

                        Uri imageUri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);

                        if (imageUri != null) {
                            try (OutputStream outputStream = getContentResolver().openOutputStream(imageUri)) {
                                if (outputStream != null) {
                                    outputStream.write(imageBytes);
                                    outputStream.flush();
                                }
                            }

                            values.clear();
                            values.put(MediaStore.Downloads.IS_PENDING, 0);

                            getContentResolver().update(imageUri, values, null, null);

                            Toast.makeText(this, "Image downloaded successfully", Toast.LENGTH_SHORT).show();
                        }
                    } else {
                        // ==============================
                        // ANDROID 9 AND BELOW
                        // ==============================
                        File picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                        File setliDir = new File(picturesDir, "Setli");

                        if (!setliDir.exists()) {
                            setliDir.mkdirs();
                        }

                        File imageFile = new File(setliDir, fileName);

                        try (FileOutputStream outputStream = new FileOutputStream(imageFile)) {
                            outputStream.write(imageBytes);
                            outputStream.flush();
                        }

                        // Make image visible in Gallery
                        MediaScannerConnection.scanFile(this, new String[]{imageFile.getAbsolutePath()}, new String[]{"image/" + imageType}, null);
                        Toast.makeText(this, "Image downloaded successfully", Toast.LENGTH_SHORT).show();
                    }
                } catch (Exception e) {
                    Log.e("Download", "Base64 image download failed", e);
                    Toast.makeText(this, "Unable to download image", Toast.LENGTH_SHORT).show();
                }
                return;
            }


            // ==============================
            // NORMAL HTTP / HTTPS DOWNLOAD
            // ==============================

            if (url == null || !(url.startsWith("http://") || url.startsWith("https://"))) {

                Log.d("Download", "Unsupported download URL: " + url);

                return;
            }

            try {

                DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));

                request.setMimeType(mimeType);

                String fileName = URLUtil.guessFileName(url, contentDisposition, mimeType);

                request.addRequestHeader("User-Agent", userAgent);

                request.setTitle(fileName);
                request.setDescription("Downloading file...");

                request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);

                request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName);

                DownloadManager downloadManager = (DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE);

                downloadManager.enqueue(request);

                Toast.makeText(this, "Download started", Toast.LENGTH_SHORT).show();

            } catch (Exception e) {

                Log.e("Download", "Download failed", e);

                Toast.makeText(this, "Unable to download file", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void showExitConfirmationDialog() {
        new AlertDialog.Builder(this)
                .setTitle("Exit App")
                .setMessage("Are you sure you want to exit the app?")
                .setNegativeButton("Cancel", (dialog, which) -> {
                    dialog.dismiss();
                })
                .setPositiveButton("Exit", (dialog, which) -> {
                    finishAffinity();
                })
                .setCancelable(false)
                .show();
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
        TextView tvSkip = onboardingContainer.findViewById(R.id.tvSkip);
        AppCompatButton btnPrimaryAction = onboardingContainer.findViewById(R.id.btnPrimaryAction);
        TextView btnBack = onboardingContainer.findViewById(R.id.btnBack);
        View dot0 = onboardingContainer.findViewById(R.id.dot0);
        View dot1 = onboardingContainer.findViewById(R.id.dot1);
        View dot2 = onboardingContainer.findViewById(R.id.dot2);
        View dot3 = onboardingContainer.findViewById(R.id.dot3);
        View dot4 = onboardingContainer.findViewById(R.id.dot4);

        List<OnboardingSlide> slides = Arrays.asList(
                new OnboardingSlide(
                        R.drawable.onboarding1,
                        "ALL-IN-ONE RENT MANAGEMENT",
                        R.drawable.dot_blue,
                        R.drawable.bg_pill_blue,
                        0xFF0056FE,
                        "Manage Your Rent, ",
                        "All in One Place",
                        "Collect rent, manage tenants, track payments, and keep your rental activity organized from one simple platform."
                ),
                new OnboardingSlide(
                        R.drawable.onboarding2,
                        "SMART PAYMENT TRACKING",
                        R.drawable.dot_blue,
                        R.drawable.bg_pill_blue,
                        0xFF0056FE,
                        "Track Every Payment ",
                        "With Ease",
                        "Stay on top of rent collections, payment status, and tenant activity with simple tracking and helpful reminders."
                ),
                new OnboardingSlide(
                        R.drawable.onboarding3,
                        "REWARDS & SMARTER MANAGEMENT",
                        R.drawable.dot_amber,
                        R.drawable.bg_pill_amber,
                        0xFFD97706,
                        "Manage Smarter. ",
                        "Earn More.",
                        "Unlock rewards, discover useful insights, and make your rent management experience simpler and more rewarding."
                ), new OnboardingSlide(
                        R.drawable.onboarding4,
                        "FOR HOSTS & LANDLORDS",
                        R.drawable.dot_blue,
                        R.drawable.bg_pill_blue,
                        0xFF0056FE,
                        "Manage Your Properties ",
                        "With Ease",
                        "List properties, manage tenants, track rent and stay on top of your property activity from one simple platform."
                ), new OnboardingSlide(
                        R.drawable.onboarding5,
                        "FOR TENANTS",
                        R.drawable.dot_blue,
                        R.drawable.bg_pill_blue,
                        0xFF0056FE,
                        "Your Rental Life, ",
                        "Made Simple",
                        "Find your rental information, manage payments, stay connected with your host and keep everything organized in one place."
                )
        );

        viewPager.setAdapter(new OnboardingAdapter(slides));

        viewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                super.onPageSelected(position);
                updateControls(position, tvSkip, btnPrimaryAction, btnBack, dot0, dot1, dot2, dot3, dot4);
            }
        });

        // Initialize state for Index 0
        updateControls(0, tvSkip, btnPrimaryAction, btnBack, dot0, dot1, dot2, dot3, dot4);

        tvSkip.setOnClickListener(v -> completeOnboarding(root));

        btnBack.setOnClickListener(v -> {
            int current = viewPager.getCurrentItem();
            if (current > 0) {
                viewPager.setCurrentItem(current - 1, true);
            }
        });

        btnPrimaryAction.setOnClickListener(v -> {
            int current = viewPager.getCurrentItem();
            if (current < slides.size() - 1) {
                viewPager.setCurrentItem(current + 1, true);
            } else {
                completeOnboarding(root);
            }
        });
    }

    private void updateControls(
            int index,
            TextView tvSkip,
            AppCompatButton btnPrimaryAction,
            TextView btnBack,
            View dot0,
            View dot1,
            View dot2,
            View dot3,
            View dot4
    ) {
        // Update Primary Action button text: "Next  ›" or "Get Started  ›"
        btnPrimaryAction.setText(index == 4 ? "Get Started  ›" : "Next  ›");

        // Update Skip button: hidden on the final slide
        tvSkip.setVisibility(index == 4 ? View.GONE : View.VISIBLE);

        // Update Back button: hidden on the first slide
        btnBack.setVisibility(index > 0 ? View.VISIBLE : View.INVISIBLE);

        // Update Indicator Dots (Pill expands to 22dp, circles are 6dp)
        updateDot(dot0, index == 0);
        updateDot(dot1, index == 1);
        updateDot(dot2, index == 2);
        updateDot(dot3, index == 3);
        updateDot(dot4, index == 4);
    }

    private void updateDot(View dot, boolean isActive) {
        ViewGroup.LayoutParams lp = dot.getLayoutParams();
        if (lp != null) {
            lp.width = dpToPx(isActive ? 22 : 6);
            dot.setLayoutParams(lp);
        }
        dot.setBackgroundResource(isActive ? R.drawable.bg_indicator_active : R.drawable.bg_indicator_inactive);
    }

    private int dpToPx(int dp) {
        return (int) (dp * getResources().getDisplayMetrics().density + 0.5f);
    }

    private void completeOnboarding(ViewGroup root) {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_COMPLETED_ONBOARDING, true)
                .apply();

        if (onboardingContainer != null) {
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
        }
    }
}
