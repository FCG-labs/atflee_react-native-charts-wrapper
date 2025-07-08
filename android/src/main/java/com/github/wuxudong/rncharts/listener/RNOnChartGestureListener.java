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

import java.lang.ref.WeakReference;

/**
 * Created by xudong on 07/03/2017.
 */
public class RNOnChartGestureListener implements OnChartGestureListener {

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
        int leftIdx = (int) Math.ceil(chart.getLowestVisibleX());
        int rightIdx = (int) Math.floor(chart.getHighestVisibleX());
        int visibleCount = rightIdx - leftIdx + 1;
        if (visibleCount < 0) visibleCount = 0;
        Boolean landscapeOverride = EdgeLabelHelper.getLandscapeOverride(chart);
        boolean isLandscape = (landscapeOverride != null) ? landscapeOverride.booleanValue() : (chart.getWidth() > chart.getHeight());
        int threshold = isLandscape ? 15 : 8;
        boolean showValues = visibleCount <= threshold;

        ChartData data = chart.getData();
        if (data != null) {
            for (Object obj : data.getDataSets()) {
                if (obj instanceof IDataSet) {
                    IDataSet set = (IDataSet) obj;
                    if (set.isDrawValuesEnabled() != showValues) {
                        set.setDrawValues(showValues);
                    }
                }
            }
        }

        XAxis axis = chart.getXAxis();
        boolean labelsDisabled = !axis.isDrawLabelsEnabled();

        Boolean explicit = EdgeLabelHelper.getExplicitFlag(chart);
        boolean desiredEdge;
        if (explicit != null) {
            desiredEdge = labelsDisabled ? true : explicit.booleanValue();
        } else {
            desiredEdge = labelsDisabled ? true : !showValues;
        }

        if (explicit == null && !labelsDisabled) {
            axis.setDrawLabels(showValues);
        }

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
