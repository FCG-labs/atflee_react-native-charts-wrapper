package com.github.wuxudong.rncharts.listener;

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
import com.github.mikephil.charting.listener.ChartTouchListener;
import com.github.mikephil.charting.listener.OnChartGestureListener;
import com.github.mikephil.charting.utils.MPPointD;
import com.github.mikephil.charting.utils.ViewPortHandler;
import com.github.wuxudong.rncharts.charts.ChartGroupHolder;
import com.github.wuxudong.rncharts.charts.helpers.EdgeLabelHelper;
import com.github.mikephil.charting.data.ChartData;
import com.github.mikephil.charting.interfaces.datasets.IDataSet;
import com.github.mikephil.charting.components.XAxis;
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

    public RNOnChartGestureListener(Chart chart) {
        this.mWeakChart = new WeakReference<>(chart);
    }

    public void setGroup(String group) {
        this.group = group;
    }

    public void setIdentifier(String identifier) {
        this.identifier = identifier;
    }

    @Override
    public void onChartGestureStart(MotionEvent me, ChartTouchListener.ChartGesture lastPerformedGesture) {
        sendEvent("chartGestureStart", me);
    }

    @Override
    public void onChartGestureEnd(MotionEvent me, ChartTouchListener.ChartGesture lastPerformedGesture) {
        adjustValueAndEdgeLabels();
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
        sendEvent("chartSingleTap", me);
    }

    @Override
    public void onChartFling(MotionEvent me1, MotionEvent me2, float velocityX, float velocityY) {
        sendEvent("chartFling", me1);
    }

    @Override
    public void onChartScale(MotionEvent me, float scaleX, float scaleY) {
        adjustValueAndEdgeLabels();
        sendEvent("chartScaled", me);
    }

    @Override
    public void onChartTranslate(MotionEvent me, float dX, float dY) {
        adjustValueAndEdgeLabels();
        sendEvent("chartTranslated", me);
    }

    private void adjustValueAndEdgeLabels() {
        Chart base = mWeakChart.get();
        if (!(base instanceof BarLineChartBase)) return;
        BarLineChartBase chart = (BarLineChartBase) base;

        // approximate number of x-entries currently visible (inclusive)
        float leftX = chart.getLowestVisibleX();
        float rightX = chart.getHighestVisibleX();

        // If user pans past the data range, clamp so that we don't count the 'blank' region
        ChartData dataForClamp = chart.getData();
        if (dataForClamp != null) {
            float minX = dataForClamp.getXMin();
            float maxX = dataForClamp.getXMax();
            if (leftX < minX) leftX = minX;
            if (rightX > maxX) rightX = maxX;
        }

        int visibleCount;
        ChartData _d = chart.getData();
        if (_d != null) {
            int totalEntries = (int) (_d.getXMax() - _d.getXMin() + 1);
            float scale = chart.getScaleX();
            if (scale < 1f) scale = 1f; // safety guard
            visibleCount = (int) Math.ceil(totalEntries / scale);
            if (visibleCount < 1) visibleCount = 1;
            if (visibleCount > totalEntries) visibleCount = totalEntries;
        } else {
            visibleCount = 0;
        }
        Boolean landscapeOverride = EdgeLabelHelper.getLandscapeOverride(chart);
        boolean isLandscape = (landscapeOverride != null) ? landscapeOverride.booleanValue() : (chart.getWidth() > chart.getHeight());
        Log.d("RNChartDebug", "[adjust] landscapeOverride=" + landscapeOverride + ", isLandscape=" + isLandscape);
        int threshold = isLandscape ? 15 : 8;
        boolean showValues = visibleCount <= threshold;
        Log.d("RNChartDebug", "[adjust] visibleCount=" + visibleCount + ", threshold=" + threshold + ", showValues=" + showValues);

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
                    Log.d("RNChartDebug", "[adjust] DataSet=" + set.getLabel() + ", baseDraw=" + baseDraw + ", desired=" + desired + ", current=" + set.isDrawValuesEnabled());
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
        if (explicit != null) {
            desiredEdge = userDisabledLabels ? true : explicit.booleanValue();
        } else {
            desiredEdge = userDisabledLabels ? true : !showValues;
        }

        boolean showAxis = desiredEdge ? false : showValues;
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
                // 1. 이벤트 객체 생성 직후 상태
                Log.d("RNChartEvent", "[sendEvent] event created: " + event);
                Log.d("RNChartEvent", "[sendEvent] action: " + action + ", chartId: " + chart.getId());
                Log.d("RNChartEvent", "[sendEvent] motionEvent: x=" + me.getX() + ", y=" + me.getY());

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

            if (group != null && identifier != null) {
                ChartGroupHolder.sync(group, identifier, chart.getScaleX(), chart.getScaleY(), (float) center.x, (float) center.y);

            }
        }
        return event;
    }
}
