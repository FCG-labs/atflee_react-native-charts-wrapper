package com.github.wuxudong.rncharts.charts;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.ViewTreeObserver;

import java.util.ArrayList;

import com.github.mikephil.charting.charts.CombinedChart;
import com.github.mikephil.charting.highlight.CombinedHighlighter;
// import com.github.mikephil.charting.highlight.Highlight;
import com.github.wuxudong.rncharts.charts.helpers.EdgeLabelHelper;
import com.github.wuxudong.rncharts.listener.RNOnChartGestureListener;
import com.github.wuxudong.rncharts.markers.RNAtfleeMarkerView;

public class AtfleeCombinedChart extends CombinedChart {
    private static final String TAG = "AtfleeMarkerDebug";
    private boolean markerTouchActive = false;
    private com.github.wuxudong.rncharts.utils.NestedScrollingHelper mNestedScrollingHelper = new com.github.wuxudong.rncharts.utils.NestedScrollingHelper();

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

    // Note: keep default highlight behavior (no Y clamping/logging)

    /**
     * 크기가 정해지기 전에 걸린 뷰포트 작업(zoom prop 의 줌·이동)을 첫 그리기 전에 돌린다.
     *
     * MPAndroidChart 3.1.0 은 크기가 없을 때 걸린 작업을 mJobs 에 쌓았다가 onSizeChanged 에서 post 한다 —
     * 그래서 새로 만든 차트의 첫 프레임은 줌이 걸리기 전(전 구간)으로 그려졌다(앳플리 「변화 전체」
     * 「전체→최근」에서 전 구간에 7칸용 큰 점이 번쩍인 원인, 2026-10-01). 부모가 post 하기 전에 가로채,
     * 크기·축이 정해진 직후(부모 onSizeChanged 뒤) 바로 돌린다. mJobs 안의 순서는 post 때와 같고,
     * prop 트랜잭션이 chart.post 로 건 러너블(visibleRange 등)보다는 먼저 돈다. 크기가 여전히 0 이면
     * 버리지 않고(부모는 그래도 post 했다) 다음 onSizeChanged 까지 둔다. 모든 CombinedChart 에 걸린다.
     * x축 라벨 모드·값 라벨은 prop 트랜잭션이 줌 전 배율로 정해 두었으므로, 첫 그리기 직전에 다시 맞춘다.
     */
    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        ArrayList<Runnable> pending = new ArrayList<>(mJobs);
        mJobs.clear();
        super.onSizeChanged(w, h, oldw, oldh);
        if (pending.isEmpty()) return;
        if (!mViewPortHandler.hasChartDimens()) {
            // 크기가 여전히 없으면 다음 onSizeChanged 까지 그대로 둔다.
            mJobs.addAll(pending);
            return;
        }
        for (Runnable job : pending) {
            job.run();
        }
        refreshLabelsBeforeNextDraw();
    }

    private void refreshLabelsBeforeNextDraw() {
        if (!(getOnChartGestureListener() instanceof RNOnChartGestureListener)) return;
        // 초기 판정(매니저 restoreInitialXAxisLabelMode)과 제스처 판정이 같은 규칙인 차트 — 가장자리 날짜를 자동으로
        // 켜고 끄는 차트 — 에서만 다시 맞춘다. 다른 차트는 첫 화면 라벨이 지금과 달라질 수 있어 건드리지 않는다.
        Boolean autoEdge = EdgeLabelHelper.hasEdgeValueFormatter(this);
        if (autoEdge == null || !autoEdge || EdgeLabelHelper.getExplicitFlag(this) != null) return;
        final RNOnChartGestureListener listener = (RNOnChartGestureListener) getOnChartGestureListener();
        final ViewTreeObserver observer = getViewTreeObserver();
        observer.addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
            @Override
            public boolean onPreDraw() {
                ViewTreeObserver current = getViewTreeObserver();
                if (current.isAlive()) current.removeOnPreDrawListener(this);
                listener.refreshLabelsForViewport();
                // 라벨 모드가 바뀌면 여백(extraOffsets)도 바뀐다 — 첫 그리기 전에 내용 영역을 다시 잡는다.
                calculateOffsets();
                return true;
            }
        });
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
        // Handle nested scrolling via helper
        mNestedScrollingHelper.saveDownCoordinates(ev);
        mNestedScrollingHelper.handleNestedScroll(ev, getParent(), markerTouchActive);

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
                        // Re-allow parent intercepts after finishing marker interaction
                        try { if (getParent() != null) getParent().requestDisallowInterceptTouchEvent(false); } catch (Throwable ignore) {}
                        if (inside) {
                            marker.dispatchClick();
                        }
                        return true;
                    }
                    break;
                case MotionEvent.ACTION_CANCEL:
                    if (markerTouchActive) {
                        markerTouchActive = false;
                        try { if (getParent() != null) getParent().requestDisallowInterceptTouchEvent(false); } catch (Throwable ignore) {}
                        return true;
                    }
                    break;
            }
        }
        // Use default event dispatch (no Y clamping/logging)

        return super.dispatchTouchEvent(ev);
    }
 
}
