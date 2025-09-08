package com.github.wuxudong.rncharts.charts;


import com.facebook.react.uimanager.ThemedReactContext;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.wuxudong.rncharts.data.DataExtract;
import com.github.wuxudong.rncharts.data.LineDataExtract;
import com.github.wuxudong.rncharts.listener.RNOnChartValueSelectedListener;
import com.github.wuxudong.rncharts.listener.RNOnChartGestureListener;

public class LineChartManager extends BarLineChartBaseManager<LineChart, Entry> {

    @Override
    public String getName() {
        return "RNLineChart";
    }

    @Override
    protected LineChart createViewInstance(ThemedReactContext reactContext) {
        LineChart lineChart =  new LineChart(reactContext);
        lineChart.setOnChartValueSelectedListener(new RNOnChartValueSelectedListener(lineChart));
        lineChart.setOnChartGestureListener(new RNOnChartGestureListener(lineChart));

        // 커스텀 렌더러 적용
        MultilineXAxisRenderer renderer = new MultilineXAxisRenderer(
                lineChart.getViewPortHandler(),
                lineChart.getXAxis(),
                lineChart.getTransformer(YAxis.AxisDependency.LEFT)
        );
        lineChart.setXAxisRenderer(renderer);

        // 값 라벨 보존을 위한 커스텀 라인 렌더러 (상단 경계에서 사라지지 않게)
        lineChart.setRenderer(new NoClipLineChartRenderer(lineChart, lineChart.getAnimator(), lineChart.getViewPortHandler()));

        // 값(label) 클리핑 해제: 상단 경계에 닿는 값 라벨이 잘리지 않도록
        lineChart.setClipValuesToContent(false);

        // Enable marker dragging by default for consistency with iOS
        lineChart.setHighlightPerDragEnabled(true);

        return lineChart;
    }


    @Override
    DataExtract getDataExtract() {
        return new LineDataExtract();
    }
}
