package com.github.wuxudong.rncharts.charts;

import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.components.YAxis;
import com.github.wuxudong.rncharts.data.BarDataExtract;
import com.github.wuxudong.rncharts.data.DataExtract;
import com.github.wuxudong.rncharts.listener.RNOnChartGestureListener;
import com.github.wuxudong.rncharts.listener.RNOnChartValueSelectedListener;

public class BarChartManager extends BarLineChartBaseManager<BarChart, BarEntry> {

    @Override
    public String getName() {
        return "RNBarChart";
    }

    @Override
    protected BarChart createViewInstance(ThemedReactContext reactContext) {
        AtfleeBarChart barChart = new AtfleeBarChart(reactContext);
        barChart.setOnChartValueSelectedListener(new RNOnChartValueSelectedListener(barChart));
        barChart.setOnChartGestureListener(new RNOnChartGestureListener(barChart));

        MultilineXAxisRenderer xRenderer = new MultilineXAxisRenderer(
            barChart.getViewPortHandler(),
            barChart.getXAxis(),
            barChart.getTransformer(YAxis.AxisDependency.LEFT)
        );
        barChart.setXAxisRenderer(xRenderer);

        // Enable marker dragging by default for consistency with iOS
        barChart.setHighlightPerDragEnabled(true);

        return barChart;
    }

    @Override
    DataExtract getDataExtract() {
        return new BarDataExtract();
    }

    @ReactProp(name = "drawValueAboveBar")
    public void setDrawValueAboveBar(BarChart chart, boolean enabled) {
        chart.setDrawValueAboveBar(enabled);
    }

    @ReactProp(name = "drawBarShadow")
    public void setDrawBarShadow(BarChart chart, boolean enabled) {
        chart.setDrawBarShadow(enabled);
    }

    @ReactProp(name = "highlightFullBarEnabled")
    public void setHighlightFullBarEnabled(BarChart chart, boolean enabled) {
        chart.setHighlightFullBarEnabled(enabled);
    }

    @ReactProp(name = "barRadius")
    public void setBarRadius(BarChart chart, float radius) {
        if (chart instanceof AtfleeBarChart) {
            ((AtfleeBarChart) chart).setRadius(radius);
        }
    }
}
