package com.github.wuxudong.rncharts.charts;

import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.formatter.ValueFormatter;

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
        int leftIndex = Math.round(chart.getLowestVisibleX());
        int rightIndex = Math.round(chart.getHighestVisibleX());
        int index = Math.round(value);
        if (index == leftIndex || index == rightIndex) {
            return baseFormatter.getFormattedValue(value);
        }
        return "";
    }

    @Override
    public String getPointLabel(Entry entry) {
        return getFormattedValue(entry.getX());
    }
}
