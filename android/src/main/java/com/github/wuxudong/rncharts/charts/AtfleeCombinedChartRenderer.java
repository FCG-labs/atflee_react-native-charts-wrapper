package com.github.wuxudong.rncharts.charts;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.charts.CombinedChart;
import com.github.mikephil.charting.renderer.CandleStickChartRenderer;
import com.github.mikephil.charting.renderer.CombinedChartRenderer;
import com.github.mikephil.charting.renderer.DataRenderer;
import com.github.mikephil.charting.renderer.LineChartRenderer;
import com.github.mikephil.charting.renderer.ScatterChartRenderer;
import com.github.mikephil.charting.utils.ViewPortHandler;

public class AtfleeCombinedChartRenderer extends CombinedChartRenderer {
    private float barRadius = 50f;
    private java.util.List<DataRenderer> renderers = new java.util.ArrayList<>();
    private AtfleeBarChartRenderer roundedBarRenderer = null;

    public AtfleeCombinedChartRenderer(CombinedChart chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
        configureRenderers();
    }

    private void configureRenderers() {
        renderers.clear();
        roundedBarRenderer = null;

        CombinedChart chart = (CombinedChart) mChart.get();
        if (chart == null)
            return;

        CombinedChart.DrawOrder[] orders = chart.getDrawOrder();

        for (CombinedChart.DrawOrder order : orders) {
            switch (order) {
                case BAR:
                    if (chart.getBarData() != null) {
                        AtfleeBarChartRenderer renderer = new AtfleeBarChartRenderer(chart, mAnimator, mViewPortHandler);
                        renderer.setRadius(barRadius);
                        roundedBarRenderer = renderer;
                        renderers.add(renderer);
                    }
                    break;
                case BUBBLE:
                    if (chart.getBubbleData() != null)
                        renderers.add(new AtfleeBubbleChartRenderer(chart.getContext(), chart, mAnimator, mViewPortHandler));
                    break;
                case LINE:
                    if (chart.getLineData() != null)
                        renderers.add(new LineChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case CANDLE:
                    if (chart.getCandleData() != null)
                        renderers.add(new CandleStickChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case SCATTER:
                    if (chart.getScatterData() != null)
                        renderers.add(new ScatterChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
            }
        }
    }

    public void setBarRadius(float radius) {
        this.barRadius = radius;
        configureRenderers();
    }

    @Override
    public void drawData(android.graphics.Canvas c) {
        for (DataRenderer renderer : renderers) {
            renderer.drawData(c);
        }
    }

    @Override
    public void drawValues(android.graphics.Canvas c) {
        for (DataRenderer renderer : renderers) {
            renderer.drawValues(c);
        }
    }

    @Override
    public void drawExtras(android.graphics.Canvas c) {
        for (DataRenderer renderer : renderers) {
            renderer.drawExtras(c);
        }
    }

    @Override
    public void initBuffers() {
        for (DataRenderer renderer : renderers) {
            renderer.initBuffers();
        }
    }
}
