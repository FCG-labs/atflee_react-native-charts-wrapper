package com.github.wuxudong.rncharts.charts;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;

import com.github.mikephil.charting.charts.CombinedChart;
import com.github.mikephil.charting.highlight.CombinedHighlighter;
import com.github.wuxudong.rncharts.markers.RNAtfleeMarkerView;

public class AtfleeCombinedChart extends CombinedChart {
    private static final String TAG = "AtfleeMarkerDebug";
    private boolean markerTouchActive = false;
    public AtfleeCombinedChart(Context context) {
        super(context);
    }

    public AtfleeCombinedChart(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public AtfleeCombinedChart(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }


    @Override
    protected void init() {
        super.init();

        // Default values are not ready here yet
        mDrawOrder = new DrawOrder[]{
                DrawOrder.BAR, DrawOrder.BUBBLE, DrawOrder.LINE, DrawOrder.CANDLE, DrawOrder.SCATTER
        };

        setHighlighter(new CombinedHighlighter(this, this));

        // Old default behaviour
        setHighlightFullBarEnabled(true);

        // Highlight should move with finger drag, matching iOS behaviour
        setHighlightPerDragEnabled(true);

        // 양쪽 drag padding 추가
        // mViewPortHandler.setDragOffsetX(35f);
        getXAxis().setSpaceMin(0.75f);
        getXAxis().setSpaceMax(0.75f);

        mRenderer = new AtfleeCombinedChartRenderer(this, mAnimator, mViewPortHandler);
    }

    public void setRadius(float radius) {
        if (mRenderer instanceof AtfleeCombinedChartRenderer) {
            AtfleeCombinedChartRenderer renderer = (AtfleeCombinedChartRenderer) mRenderer;
            renderer.setBarRadius(radius);
            invalidate();
        }
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
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
                        return true;
                    }
                    break;
                case MotionEvent.ACTION_MOVE:
                    if (markerTouchActive) {
                        return true;
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
        // Clamp touch Y into content rect so taps in extra top/bottom offsets still
        // participate in highlight detection. This avoids failing to highlight
        // points near the top when extraOffsets.top is large.
        try {
            float x = ev.getX();
            float y = ev.getY();
            float top = getViewPortHandler().contentTop();
            float bottom = getViewPortHandler().contentBottom();
            float clampedY = y;
            if (y < top) clampedY = top + 1f;
            else if (y > bottom) clampedY = bottom - 1f;

            if (clampedY != y) {
                MotionEvent adjusted = MotionEvent.obtain(ev);
                adjusted.setLocation(x, clampedY);
                boolean handled = super.dispatchTouchEvent(adjusted);
                adjusted.recycle();
                return handled;
            }
        } catch (Throwable ignore) {}

        return super.dispatchTouchEvent(ev);
    }
 
}
