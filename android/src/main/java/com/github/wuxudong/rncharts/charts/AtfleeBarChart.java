package com.github.wuxudong.rncharts.charts;

import android.content.Context;
import android.util.AttributeSet;

import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.highlight.BarHighlighter;

public class AtfleeBarChart extends BarChart {
    public AtfleeBarChart(Context context) {
        super(context);
    }

    public AtfleeBarChart(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public AtfleeBarChart(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    @Override
    protected void init() {
        super.init();

        // 양쪽 drag padding 추가
        // mViewPortHandler.setDragOffsetX(30f);

        // Highlight should follow finger drag similar to iOS
        setHighlightPerDragEnabled(true);

        mRenderer = new AtfleeBarChartRenderer(this, mAnimator, mViewPortHandler);

        setHighlighter(new BarHighlighter(this));

        getXAxis().setSpaceMin(0.75f);
        getXAxis().setSpaceMax(0.75f);
    }

    public void setRadius(float radius) {
        if (mRenderer instanceof AtfleeBarChartRenderer) {
            ((AtfleeBarChartRenderer) mRenderer).setRadius(radius);
            invalidate();
        }
    }
}
