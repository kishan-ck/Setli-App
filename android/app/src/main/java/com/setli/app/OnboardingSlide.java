package com.setli.app;

public class OnboardingSlide {
    private final int illustrationRes;
    private final String categoryText;
    private final int categoryDotRes;
    private final int categoryBgRes;
    private final int categoryTextColor;
    private final String titlePrefix;
    private final String titleHighlight;
    private final String subtitle;

    public OnboardingSlide(
        int illustrationRes,
        String categoryText,
        int categoryDotRes,
        int categoryBgRes,
        int categoryTextColor,
        String titlePrefix,
        String titleHighlight,
        String subtitle
    ) {
        this.illustrationRes = illustrationRes;
        this.categoryText = categoryText;
        this.categoryDotRes = categoryDotRes;
        this.categoryBgRes = categoryBgRes;
        this.categoryTextColor = categoryTextColor;
        this.titlePrefix = titlePrefix;
        this.titleHighlight = titleHighlight;
        this.subtitle = subtitle;
    }

    public int getIllustrationRes() {
        return illustrationRes;
    }

    public String getCategoryText() {
        return categoryText;
    }

    public int getCategoryDotRes() {
        return categoryDotRes;
    }

    public int getCategoryBgRes() {
        return categoryBgRes;
    }

    public int getCategoryTextColor() {
        return categoryTextColor;
    }

    public String getTitlePrefix() {
        return titlePrefix;
    }

    public String getTitleHighlight() {
        return titleHighlight;
    }

    public String getSubtitle() {
        return subtitle;
    }
}
