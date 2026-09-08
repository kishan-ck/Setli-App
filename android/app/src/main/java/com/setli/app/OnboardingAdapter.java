package com.setli.app;

import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import java.util.List;

public class OnboardingAdapter extends RecyclerView.Adapter<OnboardingAdapter.ViewHolder> {

    private final List<OnboardingSlide> slides;

    public OnboardingAdapter(List<OnboardingSlide> slides) {
        this.slides = slides;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_onboarding_page, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        OnboardingSlide slide = slides.get(position);

        // Illustration
        holder.ivIllustration.setImageResource(slide.getIllustrationRes());

        // Category Pill
        holder.layoutPill.setBackgroundResource(slide.getCategoryBgRes());
        holder.viewDot.setBackgroundResource(slide.getCategoryDotRes());
        holder.tvCategory.setText(slide.getCategoryText());
        holder.tvCategory.setTextColor(slide.getCategoryTextColor());

        // Dual-color Title (Black prefix + Brand Blue highlight)
        SpannableStringBuilder ssb = new SpannableStringBuilder();
        ssb.append(slide.getTitlePrefix());
        int startHighlight = ssb.length();
        ssb.append(slide.getTitleHighlight());
        ssb.setSpan(
            new ForegroundColorSpan(0xFF1D61E7), // Setli brand blue
            startHighlight,
            ssb.length(),
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
        );
        holder.tvTitle.setText(ssb);

        // Subtitle
        holder.tvSubtitle.setText(slide.getSubtitle());
    }

    @Override
    public int getItemCount() {
        return slides.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivIllustration;
        LinearLayout layoutPill;
        View viewDot;
        TextView tvCategory;
        TextView tvTitle;
        TextView tvSubtitle;

        ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivIllustration = itemView.findViewById(R.id.ivIllustration);
            layoutPill = itemView.findViewById(R.id.layoutPill);
            viewDot = itemView.findViewById(R.id.viewDot);
            tvCategory = itemView.findViewById(R.id.tvCategory);
            tvTitle = itemView.findViewById(R.id.tvTitle);
            tvSubtitle = itemView.findViewById(R.id.tvSubtitle);
        }
    }
}
