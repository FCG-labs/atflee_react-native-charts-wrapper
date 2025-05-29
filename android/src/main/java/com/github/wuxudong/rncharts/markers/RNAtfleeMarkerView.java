package com.github.wuxudong.rncharts.markers;

import android.content.Context;
import android.text.TextUtils;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.view.View.MeasureSpec;
import android.graphics.Color;
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
    private final ImageView image_arrow;
    private Entry lastEntry;
    private final ShadowLayout mShadowLayout;
    // Transparent overlay to intercept marker clicks
    private View overlayButton = null;

    private boolean arrowHidden = false;

    private static final int OVERLAY_TAG = 999;

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
        image_arrow = findViewById(R.id.image_arrow);
        // Default fade duration (milliseconds)
        fadeDuration = 300L;
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
        String raw = getChartView()
            .getXAxis()
            .getValueFormatter()
            .getFormattedValue(e.getX());

        // 줄바꿈이 있을 경우 공백으로 대체
        String title = raw.replace("\n", " ");

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

            // 타이틀 수동 설정
            if (((Map) e.getData()).containsKey("markerTitle")) {
                Object marker = ((Map) e.getData()).get("markerTitle");
                title = marker.toString();
            }
        }

        tvTitle.setText(title);

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

        if (image_arrow != null) {
            image_arrow.setVisibility(arrowHidden ? View.GONE : View.VISIBLE);
        }
    


        Chart chart = getChartView();
        if (chart != null) {
            ViewGroup parent = (ViewGroup) chart.getParent();
            if (parent != null) {
                removeOverlayButton();

                MPPointF drawingOffset = getOffsetForDrawingAtPoint(highlight.getDrawX(), highlight.getDrawY());
                // Base offset calculated for completeness
                MPPointF baseOffset = getOffset();

                float left = chart.getX() + highlight.getDrawX() + drawingOffset.x;
                float top = chart.getY() + highlight.getDrawY() + drawingOffset.y;
                android.graphics.RectF markerRect = new android.graphics.RectF(left, top,
                        left + getWidth(), top + getHeight());

                View view = new View(getContext());
                view.setTag(OVERLAY_TAG);
                view.setBackgroundColor(Color.TRANSPARENT);
                view.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        handleClick();
                    }
                });

                ViewGroup.LayoutParams base = new ViewGroup.LayoutParams(getWidth(), getHeight());
                if (parent instanceof android.widget.FrameLayout) {
                    android.widget.FrameLayout.LayoutParams lp = new android.widget.FrameLayout.LayoutParams(base);
                    lp.leftMargin = (int) left;
                    lp.topMargin = (int) top;
                    view.setLayoutParams(lp);
                } else if (parent instanceof android.widget.RelativeLayout) {
                    android.widget.RelativeLayout.LayoutParams lp = new android.widget.RelativeLayout.LayoutParams(base);
                    lp.leftMargin = (int) left;
                    lp.topMargin = (int) top;
                    view.setLayoutParams(lp);
                } else {
                    view.setLayoutParams(base);
                    view.setX(left);
                    view.setY(top);
                }

                parent.addView(view);
                overlayButton = view;
            }
        }

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

        float width = getWidth();
        float chartWidth = getChartView().getWidth();
        float offsetX = -(width / 2f);
        float offsetY;


        if (showAbove) {
            offsetY = -getHeight();
        } else {
            offsetY = 0f;
            if (imageEmotion.getVisibility() == View.VISIBLE) {
                offsetY += imageEmotion.getHeight();
            }
        }

        // 왼쪽 끝에서 잘림 방지
        if (posX + offsetX < 0) {
            offsetX = -posX;
        }
        // 오른쪽 끝에서 잘림 방지
        else if (posX + width + offsetX > chartWidth) {
            offsetX = chartWidth - posX - width;
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
                .receiveEvent(chart.getId(), "onMarkerClick", event);
        // Clear the current highlight without triggering listeners and
        // then reset marker-related state as done on iOS.
        chart.highlightValue(null, false);
        resetState();
    }

    private void removeOverlayButton() {
        if (overlayButton != null) {
            ViewParent vp = overlayButton.getParent();
            if (vp instanceof ViewGroup) {
                ((ViewGroup) vp).removeView(overlayButton);
            }
            overlayButton = null;
        }
    }

    @Override
    public void draw(android.graphics.Canvas canvas) {
        if (fadeStart > 0) {
            if (fadeDuration > 0) {
                long elapsed = System.currentTimeMillis() - fadeStart;
                float alpha = Math.min(1f, (float) elapsed / (float) fadeDuration);
                setAlpha(alpha);

                if (elapsed < fadeDuration) {
                    // Keep redrawing until the fade in animation completes
                    invalidate();
                } else {
                    // Animation finished
                    fadeStart = 0L;
                }
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
        removeOverlayButton();
    }

    public void setArrowHidden(boolean hidden) {
        this.arrowHidden = hidden;
        if (image_arrow != null) {
            image_arrow.setVisibility(hidden ? View.GONE : View.VISIBLE);
        }
    }

}
