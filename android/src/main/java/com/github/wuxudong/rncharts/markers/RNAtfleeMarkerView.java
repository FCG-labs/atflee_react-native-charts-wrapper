package com.github.wuxudong.rncharts.markers;

import android.content.Context;
import android.text.TextUtils;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.ImageView;
import android.widget.TextView;
import android.view.ViewGroup;
import android.view.View.MeasureSpec;
import com.lihang.ShadowLayout;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.github.mikephil.charting.components.MarkerView;
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.data.CandleEntry;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.mikephil.charting.utils.Utils;
import com.github.wuxudong.rncharts.R;
import com.github.wuxudong.rncharts.utils.EntryToWritableMapUtils;

import java.util.Map;

public class RNAtfleeMarkerView extends MarkerView {

    private final TextView tvTitle;
    private final TextView tvContent;
    private final ImageView imageEmotion;
    private Entry lastEntry;
    private final ImageView imageArrow;
    private final ShadowLayout mShadowLayout;
    private boolean showArrow = true;

    /**
     * Animation start timestamp and duration for fade in effect.
     */
    private long fadeStart = 0L;
    private long fadeDuration;

    public void setFadeDuration(long duration) {
        this.fadeDuration = duration;
    }

    public RNAtfleeMarkerView(Context context) {
        super(context, R.layout.atflee_marker);

        tvTitle = findViewById(R.id.x_value);
        tvContent = findViewById(R.id.y_value);
        imageEmotion = findViewById(R.id.image_emotion);

        mShadowLayout = findViewById(R.id.mShadowLayout);
        View clickable = mShadowLayout;
        if (clickable != null) {
            clickable.setOnClickListener(new OnClickListener() {
                @Override
                public void onClick(View v) {
                    handleClick();
                }
            });
        }
        // Default fade duration (milliseconds)
        fadeDuration = 300L;
        imageArrow = findViewById(R.id.image_arrow);
    }


    @Override
    public void refreshContent(Entry e, Highlight highlight) {
        lastEntry = e;
        if (fadeStart == 0L) {
            fadeStart = System.currentTimeMillis();
            // Start transparent and fade in
            setAlpha(0f);
        }

        String decimalPlaces = "0";
        String markerUnit = "";
        String markerString = "";
        String markerEmotion = "";

        // 날짜(타이틀)
        tvTitle.setText(getChartView().getXAxis().getValueFormatter().getFormattedValue(e.getX()));

        //
        if (e.getData() instanceof Map) {
            // 단위
            if (((Map) e.getData()).containsKey("markerUnit")) {
                Object marker = ((Map) e.getData()).get("markerUnit");
                markerUnit = marker.toString();
            }

            // marker 글자
            if (((Map) e.getData()).containsKey("marker")) {
                Object marker = ((Map) e.getData()).get("marker");
                markerString = marker.toString();
            }

            // decimal places
            if (((Map) e.getData()).containsKey("decimalPlaces")) {
                Object marker = ((Map) e.getData()).get("decimalPlaces");
                decimalPlaces = marker.toString();
            }

        }
        if (e instanceof CandleEntry) {
            CandleEntry ce = (CandleEntry) e;
            tvContent.setText(Utils.formatNumber(ce.getHigh(), 0, true));
        } else {
            if (markerString.isEmpty()) {
                tvContent.setText(String.format("%." + decimalPlaces + "f", e.getY()) + markerUnit);
            } else {
                tvContent.setText(markerString);
            }
        }

        // 감정 이모티콘
        if (e.getData() instanceof Map) {
            if (((Map) e.getData()).containsKey("markerEmotion")) {

                Object marker = ((Map) e.getData()).get("markerEmotion");
                markerEmotion = marker.toString();
            }
        }
        if (TextUtils.isEmpty(markerEmotion)) {
            imageEmotion.setVisibility(GONE);
        } else {
            imageEmotion.setVisibility(VISIBLE);
            if (markerEmotion.equalsIgnoreCase("1"))
                imageEmotion.setImageResource(R.drawable.emotion1);
            if (markerEmotion.equalsIgnoreCase("2"))
                imageEmotion.setImageResource(R.drawable.emotion2);
            if (markerEmotion.equalsIgnoreCase("3"))
                imageEmotion.setImageResource(R.drawable.emotion3);
            if (markerEmotion.equalsIgnoreCase("4"))
                imageEmotion.setImageResource(R.drawable.emotion4);
            if (markerEmotion.equalsIgnoreCase("5"))
                imageEmotion.setImageResource(R.drawable.emotion5);
        }

        // arrow image always prepared
        imageArrow.setImageResource(R.drawable.arrow_right_circle);
        imageArrow.setVisibility(showArrow ? VISIBLE : GONE);

        // Measure views to adjust ShadowLayout size
        tvTitle.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED);
        tvContent.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED);
        int width = Math.max(tvTitle.getMeasuredWidth(), tvContent.getMeasuredWidth());
        int height = tvTitle.getMeasuredHeight() + tvContent.getMeasuredHeight();

        if (imageEmotion.getVisibility() == VISIBLE) {
            imageEmotion.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED);
            width = Math.max(width, imageEmotion.getMeasuredWidth());
            height += imageEmotion.getMeasuredHeight();
        }
        if (imageArrow.getVisibility() == VISIBLE) {
            imageArrow.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED);
            width = Math.max(width, imageArrow.getMeasuredWidth());
            height += imageArrow.getMeasuredHeight();
        }

        width += (int) Utils.convertDpToPixel(16f); // margins inside layout
        height += (int) Utils.convertDpToPixel(8f); // vertical margins

        ViewGroup.LayoutParams params = mShadowLayout.getLayoutParams();
        if (params != null) {
            params.width = width;
            params.height = height;
            mShadowLayout.setLayoutParams(params);
        }
        mShadowLayout.requestLayout();

        super.refreshContent(e, highlight);
    }

    @Override
    public MPPointF getOffset() {
        if (imageEmotion.getVisibility() == View.VISIBLE) {
            return new MPPointF(-(getWidth() / 2), -getHeight());
        } else {
            return new MPPointF(-(getWidth() / 2), -getChartView().getHeight() + getHeight());
        }
    }

    @Override
    public MPPointF getOffsetForDrawingAtPoint(float posX, float posY) {
        float chartHeight = getChartView() != null ? getChartView().getHeight() : 0f;
        boolean showAbove = posY > chartHeight * 0.35f;

        float offsetX = -(getWidth() / 2f);
        float offsetY;

        if (showAbove) {
            offsetY = -getHeight();
        } else {
            offsetY = 0f;
            if (imageEmotion.getVisibility() == View.VISIBLE) {
                offsetY += imageEmotion.getHeight();
            }
        }

        return new MPPointF(offsetX, offsetY);
    }

    public TextView getTvTitle() {
        return tvTitle;
    }

    public TextView getTvContent() {
        return tvContent;
    }

    private void handleClick() {
        if (lastEntry == null) {
            return;
        }

        Chart chart = getChartView();
        if (chart == null) {
            return;
        }

        ReactContext reactContext = (ReactContext) getContext();
        WritableMap event = Arguments.createMap();
        event.putDouble("x", lastEntry.getX());
        event.putDouble("y", lastEntry.getY());
        event.putMap("data", EntryToWritableMapUtils.convertEntryToWritableMap(lastEntry));

        reactContext.getJSModule(RCTEventEmitter.class)
                .receiveEvent(chart.getId(), "topMarkerClick", event);

        chart.highlightValue(null);
        resetState();
    }
  
    @Override
    public void draw(android.graphics.Canvas canvas) {
        if (fadeDuration > 0 && fadeStart > 0) {
            long elapsed = System.currentTimeMillis() - fadeStart;
            if (elapsed < fadeDuration) {
                float alpha = (float) elapsed / (float) fadeDuration;
                setAlpha(alpha);
                // Continue invalidating until fade in completes
                invalidate();
            } else {
                setAlpha(1f);
                fadeStart = 0L;
            }
        }
        super.draw(canvas);
    }

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        resetState();
    }

    public void resetState() {
        fadeStart = 0L;
    }
  
    public void setShowArrow(boolean show) {
        this.showArrow = show;
    }

}
