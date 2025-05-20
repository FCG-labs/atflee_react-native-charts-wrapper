package com.github.wuxudong.rncharts.charts;

import android.content.Context;
import android.util.AttributeSet;

import com.github.mikephil.charting.charts.CombinedChart;
import com.github.mikephil.charting.highlight.CombinedHighlighter;

public class AtfleeCombinedChart extends CombinedChart {
    public AtfleeCombinedChart(Context context) {
        super(context);
    }

    public AtfleeCombinedChart(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public AtfleeCombinedChart(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }


    @Override
    protected void init() {
        super.init();

        // Default values are not ready here yet
        mDrawOrder = new DrawOrder[]{
                DrawOrder.BAR, DrawOrder.BUBBLE, DrawOrder.LINE, DrawOrder.CANDLE, DrawOrder.SCATTER
        };

        setHighlighter(new CombinedHighlighter(this, this));

        // Old default behaviour
        setHighlightFullBarEnabled(true);

        // 양쪽 drag padding 추가
        mViewPortHandler.setDragOffsetX(35f);

        mRenderer = new AtfleeCombinedChartRenderer(this, mAnimator, mViewPortHandler);
    }

    public void setRadius(float radius) {
        if (mRenderer instanceof AtfleeCombinedChartRenderer) {
            AtfleeCombinedChartRenderer renderer = (AtfleeCombinedChartRenderer) mRenderer;
            renderer.setBarRadius(radius);
            invalidate();
        }
    }

}
