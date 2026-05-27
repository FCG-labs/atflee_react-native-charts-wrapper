package com.github.wuxudong.rncharts.listener;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import android.view.MotionEvent;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.listener.BarLineChartTouchListener;
import com.github.mikephil.charting.listener.ChartTouchListener;
import com.github.mikephil.charting.listener.OnChartGestureListener;
import com.github.mikephil.charting.utils.MPPointD;
import com.github.mikephil.charting.utils.ViewPortHandler;
import com.github.wuxudong.rncharts.charts.ChartGroupHolder;
import com.github.wuxudong.rncharts.charts.helpers.EdgeLabelHelper;
import com.github.mikephil.charting.data.ChartData;
import com.github.mikephil.charting.interfaces.datasets.IDataSet;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.wuxudong.rncharts.markers.RNAtfleeMarkerView;
import android.view.View.MeasureSpec;
import java.util.WeakHashMap;

import java.lang.ref.WeakReference;

/**
 * Created by xudong on 07/03/2017.
 */
public class RNOnChartGestureListener implements OnChartGestureListener {

    /**
     * Keeps track of each IDataSet's initial drawValues flag supplied by JS.
     * If the base flag is false, values will never be shown regardless of zoom/scroll.
     * WeakHashMap avoids memory leaks when datasets are released.
     */
    private static final WeakHashMap<IDataSet, Boolean> BASE_DRAW_VALUES = new WeakHashMap<>();

    private WeakReference<Chart> mWeakChart;

    private String group = null;

    private String identifier = null;

    // Throttle 관련 필드
    private long eventThrottleMs = 100; // 기본값 100ms
    private long lastTranslateEventTime = 0;
    private long lastScaleEventTime = 0;
    private static final long CHART_GROUP_SYNC_THROTTLE_MS = 24;
    private long lastChartGroupSyncTime = 0;

    // 스크롤/제스처 종료 감지용 debounce - chart deceleration이 종료된 후
    // 마지막 chartTranslated가 보낸 값과 실제 settle 위치 사이 어긋남 보정
    private final Handler scrollSettleHandler = new Handler(Looper.getMainLooper());
    private static final long SCROLL_SETTLE_DELAY_MS = 200;
    private Runnable scrollSettleRunnable;

    public RNOnChartGestureListener(Chart chart) {
        this.mWeakChart = new WeakReference<>(chart);
    }

    public void setEventThrottle(int throttleMs) {
        this.eventThrottleMs = Math.max(0, throttleMs);
    }

    public void setGroup(String group) {
        this.group = group;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    private boolean shouldSyncChartGroup(String action) {
        if ("chartScrollStop".equals(action)
                || "chartGestureEnd".equals(action)
                || "chartPanEnd".equals(action)) {
            return true;
        }

        if (!"chartTranslated".equals(action) && !"chartScaled".equals(action)) {
            return false;
        }

        long now = System.currentTimeMillis();
        if (now - lastChartGroupSyncTime < CHART_GROUP_SYNC_THROTTLE_MS) {
            return false;
        }

        lastChartGroupSyncTime = now;
        return true;
    }

    private void syncChartGroup(String action) {
        if (group == null || identifier == null || !shouldSyncChartGroup(action)) return;
        Chart base = mWeakChart.get();
        if (!(base instanceof BarLineChartBase)) return;
        BarLineChartBase chart = (BarLineChartBase) base;
        ViewPortHandler viewPortHandler = chart.getViewPortHandler();
        MPPointD center = chart.getValuesByTouchPoint(
                viewPortHandler.getContentCenter().getX(),
                viewPortHandler.getContentCenter().getY(),
                YAxis.AxisDependency.LEFT);
        ChartGroupHolder.sync(group, identifier, chart.getScaleX(), chart.getScaleY(), (float) center.x, (float) center.y);
    }

    @Override
    public void onChartGestureStart(MotionEvent me, ChartTouchListener.ChartGesture lastPerformedGesture) {
        sendEvent("chartGestureStart", me);
    }

    @Override
    public void onChartGestureEnd(MotionEvent me, ChartTouchListener.ChartGesture lastPerformedGesture) {
        adjustValueAndEdgeLabels();
        syncChartGroup("chartGestureEnd");
        sendEvent("chartGestureEnd", me);
    }

    @Override
    public void onChartLongPressed(MotionEvent me) {
        sendEvent("chartLongPress", me);
    }

    @Override
    public void onChartDoubleTapped(MotionEvent me) {
        sendEvent("doubleTapped", me);
    }

    @Override
    public void onChartSingleTapped(MotionEvent me) {
        Chart chart = mWeakChart.get();
        if (chart instanceof BarLineChartBase) {
            BarLineChartBase barChart = (BarLineChartBase) chart;
            if (barChart.getMarker() instanceof RNAtfleeMarkerView) {
                RNAtfleeMarkerView marker = (RNAtfleeMarkerView) barChart.getMarker();
                float density = barChart.getResources().getDisplayMetrics().density;
                float pad = 20f * density; // friendlier hit slop
                float tx = me.getX();
                float ty = me.getY();
                if (marker.isPointInside(tx, ty, pad)) {
                    if (barChart.getParent() != null) {
                        barChart.getParent().requestDisallowInterceptTouchEvent(true);
                    }
                    com.github.wuxudong.rncharts.listener.RNOnChartValueSelectedListener.suppressNextClear(barChart);
                    try {
                        android.util.Log.d("AtfleeMarkerDebug", "gesture fallback hit inside marker: me=(" + tx + "," + ty + ") pad=" + pad);
                    } catch (Throwable ignore) {}
                    marker.dispatchClick();
                    return;
                }
            }
        }
        sendEvent("chartSingleTap", me);
    }

    @Override
    public void onChartFling(MotionEvent me1, MotionEvent me2, float velocityX, float velocityY) {
        sendEvent("chartFling", me1);
    }

    @Override
    public void onChartScale(MotionEvent me, float scaleX, float scaleY) {
        adjustValueAndEdgeLabels();
        syncChartGroup("chartScaled");
        
        long now = System.currentTimeMillis();
        if (eventThrottleMs == 0 || (now - lastScaleEventTime) >= eventThrottleMs) {
            sendEvent("chartScaled", me);
            lastScaleEventTime = now;
        }
    }

    @Override
    public void onChartTranslate(MotionEvent me, float dX, float dY) {
        // Deceleration이 limitTransAndScale 클램핑을 우회하여 raw mTransX가 data 경계 밖으로
        // 밀려나가는 문제를 막기 위해, raw viewport가 경계 넘으면 즉시 정지 + 경계로 보정.
        // 관성 스크롤 자체는 유지되고, boundary 도달 시점에만 자연스럽게 멈춤.
        clampDecelerationToBounds();

        adjustValueAndEdgeLabels();
        syncChartGroup("chartTranslated");
        
        long now = System.currentTimeMillis();
        if (eventThrottleMs == 0 || (now - lastTranslateEventTime) >= eventThrottleMs) {
            sendEvent("chartTranslated", me);
            lastTranslateEventTime = now;
        }

        // 마지막 chartTranslated 후 200ms 동안 추가 이벤트 없으면 chartScrollStop 발송
        // → moveViewToX가 비동기로 settle된 후 정확한 viewport 값을 JS에 전달
        scheduleScrollSettleEvent(me);
    }

    private void scheduleScrollSettleEvent(final MotionEvent me) {
        if (scrollSettleRunnable != null) {
            scrollSettleHandler.removeCallbacks(scrollSettleRunnable);
        }
        scrollSettleRunnable = new Runnable() {
            @Override
            public void run() {
                scrollSettleRunnable = null;
                syncChartGroup("chartScrollStop");
                sendEvent("chartScrollStop", me);
            }
        };
        scrollSettleHandler.postDelayed(scrollSettleRunnable, SCROLL_SETTLE_DELAY_MS);
    }

    private void clampDecelerationToBounds() {
        Chart base = mWeakChart.get();
        if (!(base instanceof BarLineChartBase)) return;
        BarLineChartBase chart = (BarLineChartBase) base;
        ChartData data = chart.getData();
        if (data == null) return;

        ViewPortHandler vph = chart.getViewPortHandler();
        MPPointD lb = chart.getValuesByTouchPoint(vph.contentLeft(), vph.contentBottom(), YAxis.AxisDependency.LEFT);
        MPPointD rt = chart.getValuesByTouchPoint(vph.contentRight(), vph.contentTop(), YAxis.AxisDependency.LEFT);
        double rawLeft = lb.x;
        double rawRight = rt.x;
        double visibleWidth = rawRight - rawLeft;
        if (visibleWidth <= 0) return;

        float spaceMin = chart.getXAxis().getSpaceMin();
        float spaceMax = chart.getXAxis().getSpaceMax();
        double allowedMin = (double) data.getXMin() - spaceMin;
        double allowedMax = (double) data.getXMax() + spaceMax;

        if (rawRight > allowedMax) {
            stopDecelerationOnTouchListener(chart);
            chart.moveViewToX((float) (allowedMax - visibleWidth));
        } else if (rawLeft < allowedMin) {
            stopDecelerationOnTouchListener(chart);
            chart.moveViewToX((float) allowedMin);
        }
    }

    private void stopDecelerationOnTouchListener(BarLineChartBase chart) {
        ChartTouchListener listener = chart.getOnTouchListener();
        if (listener instanceof BarLineChartTouchListener) {
            ((BarLineChartTouchListener) listener).stopDeceleration();
        }
    }

    private void adjustValueAndEdgeLabels() {
        Chart base = mWeakChart.get();
        if (!(base instanceof BarLineChartBase)) return;
        BarLineChartBase chart = (BarLineChartBase) base;

        // scaleX 기반 visibleCount 계산 — drag/deceleration 중에는 scaleX가 변하지 않으므로
        // boundary 도달 시 lowestVisibleX/highestVisibleX의 fluctuation에 영향받지 않고 안정적.
        int visibleCount;
        ChartData _d = chart.getData();
        if (_d != null) {
            int totalEntries = (int) (_d.getXMax() - _d.getXMin() + 1);
            float scaleX = chart.getScaleX();
            float axisRange = chart.getXAxis().getAxisMaximum() - chart.getXAxis().getAxisMinimum();
            if (scaleX > 0 && axisRange > 0) {
                visibleCount = (int) Math.round(axisRange / scaleX);
            } else {
                visibleCount = totalEntries;
            }
            if (visibleCount < 1) visibleCount = 1;
            if (visibleCount > totalEntries) visibleCount = totalEntries;
        } else {
            visibleCount = 0;
        }
        Boolean landscapeOverride = EdgeLabelHelper.getLandscapeOverride(chart);
        boolean isLandscape = (landscapeOverride != null) ? landscapeOverride.booleanValue() : (chart.getWidth() > chart.getHeight());
        int threshold = isLandscape ? 15 : 8;
        boolean showValues = visibleCount <= threshold;

        ChartData data = chart.getData();
        if (data != null) {
            for (Object obj : data.getDataSets()) {
                if (obj instanceof IDataSet) {
                    IDataSet set = (IDataSet) obj;
                    Boolean baseDraw = BASE_DRAW_VALUES.get(set);
                    if (baseDraw == null) {
                        baseDraw = set.isDrawValuesEnabled();
                        BASE_DRAW_VALUES.put(set, baseDraw);
                    }

                    // If user disabled values initially, keep them off.
                    if (!baseDraw) {
                        if (set.isDrawValuesEnabled()) {
                            set.setDrawValues(false);
                        }
                        continue;
                    }

                    boolean desired = showValues;
                    if (set.isDrawValuesEnabled() != desired) {
                        set.setDrawValues(desired);
                    }
                }
            }
        }

        XAxis axis = chart.getXAxis();
        Boolean userDraw = EdgeLabelHelper.getUserDrawLabels(chart);
        boolean userDisabledLabels = userDraw != null && !userDraw.booleanValue();

        Boolean explicit = EdgeLabelHelper.getExplicitFlag(chart);
        boolean desiredEdge;
        if (userDisabledLabels) {
            desiredEdge = false;
        } else if (explicit != null) {
            desiredEdge = explicit.booleanValue();
        } else {
            desiredEdge = !showValues;
        }

        boolean showAxis = userDisabledLabels ? false : (desiredEdge ? false : showValues);
        axis.setDrawLabels(showAxis);

        EdgeLabelHelper.setEnabled(chart, desiredEdge);
        EdgeLabelHelper.applyPadding(chart);
        EdgeLabelHelper.update(chart, chart.getLowestVisibleX(), chart.getHighestVisibleX());

        chart.invalidate();
    }

    private void sendEvent(String action, MotionEvent me) {
        Chart chart = mWeakChart.get();
        if (chart != null) {

            WritableMap event = getEvent(action, me, chart);
            try {
                ReactContext reactContext = (ReactContext) chart.getContext();

                reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                    chart.getId(),
                    "topChange",
                    event);

            } catch (Exception e) {
                Log.e("RNChartEvent", "[sendEvent] Exception in receiveEvent", e);
            }
        }
    }

    @NonNull
    private WritableMap getEvent(String action, MotionEvent me, Chart chart) {
        WritableMap event = Arguments.createMap();

        event.putString("action", action);

        if (chart instanceof BarLineChartBase) {
//            BarLineChartBase barLineChart = (BarLineChartBase) chart;
            ViewPortHandler viewPortHandler = chart.getViewPortHandler();
            event.putDouble("scaleX", chart.getScaleX());
            event.putDouble("scaleY", chart.getScaleY());

            MPPointD center = ((BarLineChartBase) chart).getValuesByTouchPoint(viewPortHandler.getContentCenter().getX(), viewPortHandler.getContentCenter().getY(), YAxis.AxisDependency.LEFT);
            event.putDouble("centerX", center.x);
            event.putDouble("centerY", center.y);

            MPPointD leftBottom = ((BarLineChartBase) chart).getValuesByTouchPoint(
                    viewPortHandler.contentLeft(),
                    viewPortHandler.contentBottom(),
                    YAxis.AxisDependency.LEFT);
            MPPointD rightTop = ((BarLineChartBase) chart).getValuesByTouchPoint(
                    viewPortHandler.contentRight(),
                    viewPortHandler.contentTop(),
                    YAxis.AxisDependency.LEFT);

            float minX = chart.getData() != null ? chart.getData().getXMin() : Float.MIN_VALUE;
            float maxX = chart.getData() != null ? chart.getData().getXMax() : Float.MAX_VALUE;

            float spaceMin = chart.getXAxis().getSpaceMin();
            float spaceMax = chart.getXAxis().getSpaceMax();

            double allowedMin = minX - spaceMin;
            double allowedMax = maxX + spaceMax;

            double originalWidth = rightTop.x - leftBottom.x;
            double leftValue = leftBottom.x;
            double rightValue = rightTop.x;

            if (leftValue < allowedMin) {
                leftValue = allowedMin;
                rightValue = leftValue + originalWidth;
            }

            if (rightValue > allowedMax) {
                rightValue = allowedMax;
                leftValue = rightValue - originalWidth;
            }

            if (leftValue < allowedMin) leftValue = allowedMin;
            if (rightValue > allowedMax) rightValue = allowedMax;

            event.putDouble("left", leftValue);
            event.putDouble("bottom", leftBottom.y);
            event.putDouble("right", rightValue);
            event.putDouble("top", rightTop.y);

            com.github.wuxudong.rncharts.charts.helpers.EdgeLabelHelper.update(chart, leftValue, rightValue);

        }
        return event;
    }
}
