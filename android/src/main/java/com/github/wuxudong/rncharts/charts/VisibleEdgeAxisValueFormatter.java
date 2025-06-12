package com.github.wuxudong.rncharts.charts;

import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.formatter.ValueFormatter;
import com.github.mikephil.charting.utils.MPPointD;
import com.github.mikephil.charting.utils.ViewPortHandler;

public class VisibleEdgeAxisValueFormatter extends ValueFormatter {
    private final BarLineChartBase chart;
    private final ValueFormatter baseFormatter;
    private boolean enabled;

    public VisibleEdgeAxisValueFormatter(BarLineChartBase chart, ValueFormatter baseFormatter, boolean enabled) {
        this.chart = chart;
        this.baseFormatter = baseFormatter;
        this.enabled = enabled;
    }

    public ValueFormatter getBaseFormatter() {
        return baseFormatter;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    @Override
    public String getFormattedValue(float value) {
        if (!enabled) {
            return baseFormatter.getFormattedValue(value);
        }
        float lowest;
        float highest;

        ViewPortHandler handler = chart.getViewPortHandler();
        if (handler != null) {
            MPPointD leftBottom = chart.getValuesByTouchPoint(handler.contentLeft(), handler.contentBottom(), YAxis.AxisDependency.LEFT);
            MPPointD rightTop = chart.getValuesByTouchPoint(handler.contentRight(), handler.contentTop(), YAxis.AxisDependency.LEFT);
            lowest = (float) leftBottom.x;
            highest = (float) rightTop.x;
            MPPointD.recycleInstance(leftBottom);
            MPPointD.recycleInstance(rightTop);
        } else {
            lowest = chart.getLowestVisibleX();
            highest = chart.getHighestVisibleX();
        }

        // if the chart hasn't calculated a range yet fall back to the base
        if (highest == lowest) {
            return baseFormatter.getFormattedValue(value);
        }

        int leftIndex = (int) Math.ceil(lowest);
        int rightIndex = (int) Math.floor(highest);

        int index = Math.round(value);
        if (index == leftIndex) {
            return baseFormatter.getFormattedValue(lowest);
        }
        if (index == rightIndex) {
            return baseFormatter.getFormattedValue(highest);
        }
        return "";
    }

    @Override
    public String getPointLabel(Entry entry) {
        return getFormattedValue(entry.getX());
    }
}
