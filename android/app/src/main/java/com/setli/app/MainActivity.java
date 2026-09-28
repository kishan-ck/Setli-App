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
import android.webkit.CookieManager;
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
                }
            }
        });

        WebView webView = getBridge().getWebView();

        webView.setDownloadListener((url, userAgent, contentDisposition, mimeType, contentLength) -> {

            // ==============================
            // 1. BASE64 / DATA URI DOWNLOAD (All file types: PDF, ZIP, Images, CSV)
            // ==============================
            if (url != null && url.startsWith("data:")) {
                try {
                    String[] parts = url.split(",", 2);
                    if (parts.length != 2) {
                        Toast.makeText(this, "Invalid download data", Toast.LENGTH_SHORT).show();
                        return;
                    }

                    String header = parts[0].toLowerCase();
                    String base64Data = parts[1];
                    String fileExt = "bin";
                    String resolvedMime = mimeType != null ? mimeType : "application/octet-stream";

                    if (header.contains("pdf")) {
                        fileExt = "pdf";
                        resolvedMime = "application/pdf";
                    } else if (header.contains("zip")) {
                        fileExt = "zip";
                        resolvedMime = "application/zip";
                    } else if (header.contains("csv")) {
                        fileExt = "csv";
                        resolvedMime = "text/csv";
                    } else if (header.contains("sheet") || header.contains("excel") || header.contains("xlsx")) {
                        fileExt = "xlsx";
                        resolvedMime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                    } else if (header.contains("image/png")) {
                        fileExt = "png";
                        resolvedMime = "image/png";
                    } else if (header.contains("image/jpeg") || header.contains("image/jpg")) {
                        fileExt = "jpg";
                        resolvedMime = "image/jpeg";
                    } else if (header.contains("image/webp")) {
                        fileExt = "webp";
                        resolvedMime = "image/webp";
                    }

                    byte[] fileBytes = Base64.decode(base64Data, Base64.DEFAULT);
                    String fileName = "Setli_" + System.currentTimeMillis() + "." + fileExt;

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        ContentValues values = new ContentValues();
                        values.put(MediaStore.Downloads.DISPLAY_NAME, fileName);
                        values.put(MediaStore.Downloads.MIME_TYPE, resolvedMime);
                        values.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
                        values.put(MediaStore.Downloads.IS_PENDING, 1);

                        Uri fileUri = getContentResolver().insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
                        if (fileUri != null) {
                            try (OutputStream outputStream = getContentResolver().openOutputStream(fileUri)) {
                                if (outputStream != null) {
                                    outputStream.write(fileBytes);
                                    outputStream.flush();
                                }
                            }
                            values.clear();
                            values.put(MediaStore.Downloads.IS_PENDING, 0);
                            getContentResolver().update(fileUri, values, null, null);
                            Toast.makeText(this, "Downloaded " + fileName, Toast.LENGTH_SHORT).show();
                        }
                    } else {
                        File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                        if (!downloadsDir.exists()) downloadsDir.mkdirs();
                        File destFile = new File(downloadsDir, fileName);
                        try (FileOutputStream outputStream = new FileOutputStream(destFile)) {
                            outputStream.write(fileBytes);
                            outputStream.flush();
                        }
                        MediaScannerConnection.scanFile(this, new String[]{destFile.getAbsolutePath()}, new String[]{resolvedMime}, null);
                        Toast.makeText(this, "Downloaded " + fileName, Toast.LENGTH_SHORT).show();
                    }
                } catch (Exception e) {
                    Log.e("Download", "Base64 download failed", e);
                    Toast.makeText(this, "Unable to save file", Toast.LENGTH_SHORT).show();
                }
                return;
            }

            // ==============================
            // 2. REMOTE HTTP / HTTPS DOWNLOAD
            // ==============================
            if (url == null || !(url.startsWith("http://") || url.startsWith("https://"))) {
                Log.d("Download", "Unsupported download URL: " + url);
                return;
            }

            try {
                // Extract filename from Content-Disposition if present
                String fileName = null;
                if (contentDisposition != null && !contentDisposition.isEmpty()) {
                    int fnIndex = contentDisposition.indexOf("filename=");
                    if (fnIndex != -1) {
                        fileName = contentDisposition.substring(fnIndex + 9).trim();
                        if (fileName.contains(";")) {
                            fileName = fileName.substring(0, fileName.indexOf(";")).trim();
                        }
                        if (fileName.startsWith("\"") && fileName.endsWith("\"") && fileName.length() > 1) {
                            fileName = fileName.substring(1, fileName.length() - 1);
                        }
                    }
                }
                if (fileName == null || fileName.isEmpty()) {
                    fileName = URLUtil.guessFileName(url, contentDisposition, mimeType);
                }

                // Detect and fix file extensions and MIME types
                String urlLower = url.toLowerCase();
                String dispLower = contentDisposition != null ? contentDisposition.toLowerCase() : "";
                String resolvedMime = mimeType;

                if (urlLower.contains(".pdf") || dispLower.contains(".pdf") || (fileName != null && fileName.toLowerCase().endsWith(".pdf"))) {
                    resolvedMime = "application/pdf";
                    if (fileName != null && !fileName.toLowerCase().endsWith(".pdf")) {
                        fileName = (fileName.endsWith(".bin") ? fileName.substring(0, fileName.length() - 4) : fileName) + ".pdf";
                    }
                } else if (urlLower.contains(".zip") || dispLower.contains(".zip") || (fileName != null && fileName.toLowerCase().endsWith(".zip"))) {
                    resolvedMime = "application/zip";
                    if (fileName != null && !fileName.toLowerCase().endsWith(".zip")) {
                        fileName = (fileName.endsWith(".bin") ? fileName.substring(0, fileName.length() - 4) : fileName) + ".zip";
                    }
                } else if (urlLower.contains(".csv") || dispLower.contains(".csv") || (fileName != null && fileName.toLowerCase().endsWith(".csv"))) {
                    resolvedMime = "text/csv";
                    if (fileName != null && !fileName.toLowerCase().endsWith(".csv")) {
                        fileName = (fileName.endsWith(".bin") ? fileName.substring(0, fileName.length() - 4) : fileName) + ".csv";
                    }
                }

                DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                if (resolvedMime != null && !resolvedMime.isEmpty() && !resolvedMime.equals("application/octet-stream")) {
                    request.setMimeType(resolvedMime);
                }

                request.addRequestHeader("User-Agent", userAgent);

                // Attach session cookies so authenticated files (invoices, reports, leases) download properly
                String cookie = CookieManager.getInstance().getCookie(url);
                if (cookie != null) {
                    request.addRequestHeader("Cookie", cookie);
                }
                // Bypass headers for local development & tunnels
                request.addRequestHeader("bypass-tunnel-reminder", "true");
                request.addRequestHeader("ngrok-skip-browser-warning", "true");
                request.addRequestHeader("Accept", "application/pdf, application/zip, text/csv, */*");

                request.setTitle(fileName);
                request.setDescription("Downloading " + fileName);
                request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, fileName);

                DownloadManager downloadManager = (DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE);
                downloadManager.enqueue(request);

                Toast.makeText(this, "Downloading " + fileName, Toast.LENGTH_SHORT).show();

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
        btnPrimaryAction.setText(index == 4 ? "Get Started  ›" : "Next  ›");
        tvSkip.setVisibility(index == 4 ? View.GONE : View.VISIBLE);
        btnBack.setVisibility(index > 0 ? View.VISIBLE : View.INVISIBLE);

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