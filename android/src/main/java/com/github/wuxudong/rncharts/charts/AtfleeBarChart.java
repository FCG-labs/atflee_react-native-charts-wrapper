package com.github.wuxudong.rncharts.charts;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;

import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.highlight.BarHighlighter;
import com.github.wuxudong.rncharts.markers.RNAtfleeMarkerView;

public class AtfleeBarChart extends BarChart {
    private static final String TAG = "AtfleeMarkerDebug";
    private boolean markerTouchActive = false;
    private com.github.wuxudong.rncharts.utils.NestedScrollingHelper mNestedScrollingHelper = new com.github.wuxudong.rncharts.utils.NestedScrollingHelper();

    public AtfleeBarChart(Context context) {
        super(context);
    }

    public AtfleeBarChart(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public AtfleeBarChart(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    @Override
    protected void init() {
        super.init();

        // 양쪽 drag padding 추가
        // mViewPortHandler.setDragOffsetX(30f);

        // Highlight should follow finger drag similar to iOS
        setHighlightPerDragEnabled(true);

        mRenderer = new AtfleeBarChartRenderer(this, mAnimator, mViewPortHandler);

        setHighlighter(new BarHighlighter(this));

        getXAxis().setSpaceMin(0.75f);
        getXAxis().setSpaceMax(0.75f);
    }

    public void setRadius(float radius) {
        if (mRenderer instanceof AtfleeBarChartRenderer) {
            ((AtfleeBarChartRenderer) mRenderer).setRadius(radius);
            invalidate();
        }
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        // Handle nested scrolling via helper
        mNestedScrollingHelper.saveDownCoordinates(ev);
        mNestedScrollingHelper.handleNestedScroll(ev, getParent(), markerTouchActive);

        // Intercept touches inside marker bounds before MPChart processes them
        if (getMarker() instanceof RNAtfleeMarkerView) {
            RNAtfleeMarkerView marker = (RNAtfleeMarkerView) getMarker();
            float x = ev.getX();
            float y = ev.getY();
            float pad = 20f * getResources().getDisplayMetrics().density;

            switch (ev.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    if (marker.isPointInside(x, y, pad)) {
                        markerTouchActive = true;
                        try { Log.d(TAG, "chart intercept DOWN inside marker: (" + x + "," + y + ") pad=" + pad); } catch (Throwable ignore) {}
                        try { if (getParent() != null) getParent().requestDisallowInterceptTouchEvent(true); } catch (Throwable ignore) {}
                        return true; // consume
                    }
                    break;
                case MotionEvent.ACTION_MOVE:
                    if (markerTouchActive) {
                        return true; // consume entire gesture
                    }
                    break;
                case MotionEvent.ACTION_UP:
                    if (markerTouchActive) {
                        markerTouchActive = false;
                        boolean inside = marker.isPointInside(x, y, pad);
                        try { Log.d(TAG, "chart intercept UP insideMarker=" + inside + " at (" + x + "," + y + ")"); } catch (Throwable ignore) {}
                        if (inside) {
                            marker.dispatchClick();
                        }
                        return true;
                    }
                    break;
                case MotionEvent.ACTION_CANCEL:
                    if (markerTouchActive) {
                        markerTouchActive = false;
                        return true;
                    }
                    break;
            }
        }

        return super.dispatchTouchEvent(ev);
    }
}
