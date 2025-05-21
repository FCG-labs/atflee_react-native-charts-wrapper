package com.github.wuxudong.rncharts.charts;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.charts.CombinedChart;
import com.github.mikephil.charting.renderer.CandleStickChartRenderer;
import com.github.mikephil.charting.renderer.CombinedChartRenderer;
import com.github.mikephil.charting.renderer.LineChartRenderer;
import com.github.mikephil.charting.renderer.ScatterChartRenderer;
import com.github.mikephil.charting.utils.ViewPortHandler;
import com.github.mikephil.charting.renderer.DataRenderer;

public class AtfleeCombinedChartRenderer extends CombinedChartRenderer {
    private float barRadius = 50f;
    private final java.util.List<DataRenderer> customRenderers = new java.util.ArrayList<>();
    private AtfleeBarChartRenderer roundedBarRenderer;

    public AtfleeCombinedChartRenderer(CombinedChart chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
        configureRenderers();
    }

    private void configureRenderers() {
        customRenderers.clear();
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
                        customRenderers.add(renderer);
                    }
                    break;
                case BUBBLE:
                    if (chart.getBubbleData() != null)
                        customRenderers.add(new AtfleeBubbleChartRenderer(chart.getContext(), chart, mAnimator, mViewPortHandler));
                    break;
                case LINE:
                    if (chart.getLineData() != null)
                        customRenderers.add(new LineChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case CANDLE:
                    if (chart.getCandleData() != null)
                        customRenderers.add(new CandleStickChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case SCATTER:
                    if (chart.getScatterData() != null)
                        customRenderers.add(new ScatterChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
            }
        }
    }

    @Override
    public void drawData(android.graphics.Canvas c) {
        for (DataRenderer renderer : customRenderers) {
            renderer.drawData(c);
        }
    }

    @Override
    public void drawValues(android.graphics.Canvas c) {
        for (DataRenderer renderer : customRenderers) {
            renderer.drawValues(c);
        }
    }

    @Override
    public void drawExtras(android.graphics.Canvas c) {
        for (DataRenderer renderer : customRenderers) {
            renderer.drawExtras(c);
        }
    }

    @Override
    public void initBuffers() {
        for (DataRenderer renderer : customRenderers) {
            renderer.initBuffers();
        }
    }

    public void setBarRadius(float radius) {
        this.barRadius = radius;
        configureRenderers();
    }
}
