package com.github.wuxudong.rncharts.markers;

import android.annotation.SuppressLint;
import android.content.Context;
import android.text.TextUtils;
import android.util.Log;
import android.view.MotionEvent;
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
import com.github.wuxudong.rncharts.listener.RNOnChartValueSelectedListener;

import java.util.Map;

public class RNAtfleeMarkerView extends MarkerView {

    private static final String TAG = "AtfleeMarkerDebug";

    private final TextView tvTitle;
    private final TextView tvContent;
    private final ImageView imageEmotion;
    private final ImageView image_arrow;
    private Entry lastEntry;
    private final ShadowLayout mShadowLayout;
    // Transparent overlay to intercept taps on the marker only
    private View overlayButton = null;
    // When true, marker won't draw (used to suppress drawing during chart touches)
    private volatile boolean suppressOnTouch = false;

    private boolean arrowHidden = false;
    private boolean fixedOnTop = false;

    private static final int OVERLAY_TAG = 999;
    private static final float HIT_SLOP_DP = 12f; // legacy: kept for compatibility

    // Cache of last drawn position and size (in chart coordinates)
    private float lastLeftInChart = Float.NaN;
    private float lastTopInChart = Float.NaN;
    private int lastMeasuredWidth = 0;
    private int lastMeasuredHeight = 0;

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


    @SuppressLint("ClickableViewAccessibility")
    @Override
    public void refreshContent(Entry e, Highlight highlight) {
        Log.d(TAG, "refreshContent: entry x=" + e.getX() + ", y=" + e.getY()
                + ", drawX=" + highlight.getDrawX() + ", drawY=" + highlight.getDrawY());
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



        // Ensure the marker has concrete measured dimensions
        int wSpec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED);
        int hSpec = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED);
        measure(wSpec, hSpec);
        layout(0, 0, getMeasuredWidth(), getMeasuredHeight());

        // Store last drawn geometry in chart coordinates for hit-testing
        MPPointF drawingOffset = getOffsetForDrawingAtPoint(highlight.getDrawX(), highlight.getDrawY());
        lastLeftInChart = highlight.getDrawX() + drawingOffset.x;
        lastTopInChart = highlight.getDrawY() + drawingOffset.y;
        lastMeasuredWidth = getMeasuredWidth();
        lastMeasuredHeight = getMeasuredHeight();
        Log.d(TAG, "computed markerRect: leftInChart=" + lastLeftInChart + ", topInChart=" + lastTopInChart
                + ", size=" + lastMeasuredWidth + "x" + lastMeasuredHeight);

        // If chart touch suppression is active, do not attach/update overlay
        // and avoid any interactive hit area.
        if (!suppressOnTouch) {
            // Update or attach a small transparent overlay directly above the marker area
            // so that taps on the marker are consumed before reaching the chart.
            attachOrUpdateOverlay();
        } else {
            removeOverlayButton();
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
        boolean showAbove = fixedOnTop ? true : posY > chartHeight * 0.35f;

        float width = getWidth();
        float chartWidth = getChartView().getWidth();
        float offsetX = -(width / 2f);
        float offsetY;


        if (fixedOnTop) {
            offsetY = 8f - posY;
        } else if (showAbove) {
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

    public void setSuppressOnTouch(boolean suppress) {
        this.suppressOnTouch = suppress;
    }

    private void handleClick() {
        Chart chart = getChartView();
        if (chart == null) {
            return;
        }

        // If there's no active highlight, do not emit a click event.
        // Just remove any stale overlay and clear state.
        com.github.mikephil.charting.highlight.Highlight[] hs = chart.getHighlighted();
        if (hs == null || hs.length == 0 || lastEntry == null) {
            removeOverlayButton();
            lastEntry = null;
            chart.invalidate();
            return;
        }

        // Log current highlight state prior to click handling
        try {
            Highlight[] highlights = chart.getHighlighted();
            if (highlights != null) {
                for (int i = 0; i < highlights.length; i++) {
                    Highlight h = highlights[i];
                    Log.d(TAG, "handleClick: currentHighlight[" + i + "] xIndex=" + h.getX() +
                            ", dataSetIndex=" + h.getDataSetIndex() + ", xPx=" + h.getXPx() + ", yPx=" + h.getYPx());
                }
            } else {
                Log.d(TAG, "handleClick: no current highlights");
            }
        } catch (Throwable ignore) {}

        ReactContext reactContext = (ReactContext) getContext();
        WritableMap event = Arguments.createMap();
        event.putDouble("x", lastEntry.getX());
        event.putDouble("y", lastEntry.getY());
        event.putMap("data", EntryToWritableMapUtils.convertEntryToWritableMap(lastEntry));

        Log.d(TAG, "Sending event topMarkerClick for entry x=" + lastEntry.getX() + ", y=" + lastEntry.getY());
        reactContext.getJSModule(RCTEventEmitter.class)
                .receiveEvent(chart.getId(), "topMarkerClick", event);
        // Suppress next clear-select emission from chart and then clear state
        RNOnChartValueSelectedListener.suppressNextClear(chart);
        Log.d(TAG, "suppressNextClear set; resetting state and clearing highlight");
        // Inform JS about the marker click, then clear state to hide the marker
        resetState();
    }

    /**
     * Remove overlay and local entry without altering chart highlight state.
     * Useful for cleanup when highlight is cleared externally.
     */
    public void detachOverlayIfPresent() {
        lastEntry = null;
        // Clear cached geometry
        lastLeftInChart = Float.NaN;
        lastTopInChart = Float.NaN;
        lastMeasuredWidth = 0;
        lastMeasuredHeight = 0;
        removeOverlayButton();
    }

    /**
     * Called by external gesture listeners to simulate a user tap on the marker.
     */
    public void dispatchClick() {
        handleClick();
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

    /**
     * Adds or updates a transparent overlay view positioned exactly over the
     * last drawn marker bounds. This ensures a tap on the marker triggers only
     * the marker event, without also triggering chart tap/highlight events.
     */
    private void attachOrUpdateOverlay() {
        Chart chart = getChartView();
        if (chart == null) return;

        if (Float.isNaN(lastLeftInChart) || Float.isNaN(lastTopInChart)) return;
        if (lastMeasuredWidth <= 0 || lastMeasuredHeight <= 0) return;

        ViewParent parent = chart.getParent();
        if (!(parent instanceof ViewGroup)) return;
        ViewGroup vg = (ViewGroup) parent;

        if (overlayButton == null) {
            overlayButton = new View(getContext());
            // Restore transparent hit area
            overlayButton.setBackgroundColor(Color.TRANSPARENT);
            overlayButton.setClickable(true);
            overlayButton.setFocusable(true);
            // Keep overlay out of accessibility focus
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN) {
                overlayButton.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
            }
            overlayButton.setOnTouchListener((v, event) -> {
                int action = event.getAction();
                try {
                    float absX = v.getX() + event.getX();
                    float absY = v.getY() + event.getY();
                    Log.d(TAG, "overlayTouch action=" + action +
                            " rel=(" + event.getX() + "," + event.getY() + ")" +
                            " abs=(" + absX + "," + absY + ") size=" + v.getWidth() + "x" + v.getHeight());
                } catch (Throwable ignore) {}

                switch (action) {
                    case MotionEvent.ACTION_DOWN:
                        try { vg.requestDisallowInterceptTouchEvent(true); } catch (Throwable ignore) {}
                        v.setPressed(true);
                        return true; // consume DOWN to prevent Chart from receiving it
                    case MotionEvent.ACTION_UP:
                        v.setPressed(false);
                        // Safety: ensure UP is inside overlay bounds
                        if (event.getX() >= 0 && event.getY() >= 0 && event.getX() <= v.getWidth() && event.getY() <= v.getHeight()) {
                            try { v.performClick(); } catch (Throwable ignore) {}
                            handleClick();
                        }
                        return true;
                    case MotionEvent.ACTION_CANCEL:
                        v.setPressed(false);
                        return true;
                    default:
                        return true; // consume all to block underlying chart
                }
            });
            vg.addView(overlayButton);
            Log.d(TAG, "overlay created");
        }

        // Update size and absolute position (relative to chart's parent)
        ViewGroup.LayoutParams lp = overlayButton.getLayoutParams();
        // Add a small padding around marker bounds for friendlier taps
        int pad = Math.round(8f * getResources().getDisplayMetrics().density);
        int w = lastMeasuredWidth + pad * 2;
        int h = lastMeasuredHeight + pad * 2;
        if (lp == null) {
            lp = new ViewGroup.LayoutParams(w, h);
        } else {
            lp.width = w;
            lp.height = h;
        }
        overlayButton.setLayoutParams(lp);
        overlayButton.requestLayout();
        overlayButton.invalidate();

        // Position overlay based on chart's current position plus marker bounds
        float absX = chart.getLeft() + lastLeftInChart;
        float absY = chart.getTop() + lastTopInChart;
        overlayButton.setX(absX - pad);
        overlayButton.setY(absY - pad);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            overlayButton.setElevation(10000f);
            overlayButton.setTranslationZ(10000f);
        }
        overlayButton.bringToFront();
        overlayButton.setVisibility(VISIBLE);

        // Debug logs for positioning
        try {
            Log.d(TAG, "overlay position set: pos=(" + (absX - pad) + "," + (absY - pad) + ") size=" + w + "x" + h
                    + " chart L/T=(" + chart.getLeft() + "," + chart.getTop() + ")"
                    + " markerInChart L/T=(" + lastLeftInChart + "," + lastTopInChart + ")"
                    + " entry(x,y)=(" + (lastEntry != null ? lastEntry.getX() : -1) + "," + (lastEntry != null ? lastEntry.getY() : -1) + ")");
        } catch (Throwable ignore) {}
    }

    /**
     * Returns true if the supplied (x, y) in chart coordinates lies within
     * the marker's last drawn bounds, expanded by padPx on all sides.
     */
    public boolean isPointInside(float x, float y, float padPx) {
        if (Float.isNaN(lastLeftInChart) || Float.isNaN(lastTopInChart)) return false;
        int w = lastMeasuredWidth > 0 ? lastMeasuredWidth : getWidth();
        int h = lastMeasuredHeight > 0 ? lastMeasuredHeight : getHeight();
        if (w <= 0 || h <= 0) return false;
        float left = lastLeftInChart - padPx;
        float top = lastTopInChart - padPx;
        float right = lastLeftInChart + w + padPx;
        float bottom = lastTopInChart + h + padPx;
        return x >= left && x <= right && y >= top && y <= bottom;
    }

    @Override
    public void draw(android.graphics.Canvas canvas) {
        if (suppressOnTouch) {
            // Skip drawing entirely during chart touch suppression
            return;
        }
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
        lastEntry = null;

        Chart chart = getChartView();
        if (chart != null) {
            // Clear the current highlight and redraw the chart
            chart.highlightValue(null);
            chart.invalidate();
        }

        removeOverlayButton();
    }

    public void setArrowHidden(boolean hidden) {
        this.arrowHidden = hidden;
        if (image_arrow != null) {
            image_arrow.setVisibility(hidden ? View.GONE : View.VISIBLE);
        }
    }

    public void setFixedOnTop(boolean fixed) {
        this.fixedOnTop = fixed;
    }

}
