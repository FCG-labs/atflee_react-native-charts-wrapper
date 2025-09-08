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

    public AtfleeCombinedChartRenderer(CombinedChart chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
    }

    @Override
    public void createRenderers() {

        mRenderers.clear();

        CombinedChart chart = (CombinedChart)mChart.get();
        if (chart == null)
            return;

        CombinedChart.DrawOrder[] orders = chart.getDrawOrder();

        for (CombinedChart.DrawOrder order : orders) {

            switch (order) {
                case BAR:
                    if (chart.getBarData() != null) {
                        AtfleeBarChartRenderer renderer = new AtfleeBarChartRenderer(chart, mAnimator, mViewPortHandler);
                        renderer.setRadius(barRadius);
                        mRenderers.add(renderer);
                    }
                    break;
                case BUBBLE:
                    if (chart.getBubbleData() != null)
                        mRenderers.add(new AtfleeBubbleChartRenderer(chart.getContext(), chart, mAnimator, mViewPortHandler));
                    break;
                case LINE:
                    if (chart.getLineData() != null)
                        // Use no-clip renderer so value labels near top edge remain visible
                        mRenderers.add(new NoClipLineChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case CANDLE:
                    if (chart.getCandleData() != null)
                        mRenderers.add(new CandleStickChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case SCATTER:
                    if (chart.getScatterData() != null)
                        mRenderers.add(new ScatterChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
            }
        }
    }

    public void setBarRadius(float radius) {
        this.barRadius = radius;
        for (com.github.mikephil.charting.renderer.DataRenderer renderer : mRenderers) {
            if (renderer instanceof AtfleeBarChartRenderer) {
                ((AtfleeBarChartRenderer) renderer).setRadius(radius);
            }
        }
    }
}
