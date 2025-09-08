package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Path;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.charts.RadarChart;
import com.github.mikephil.charting.renderer.RadarChartRenderer;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.mikephil.charting.utils.ViewPortHandler;

/**
 * Radar renderer that clips all dataset drawing to the chart's circular content
 * area so the filled/stroked shape never bleeds outside the web/radius due to
 * float rounding or stroke width.
 */
public class ClippedRadarChartRenderer extends RadarChartRenderer {

    private final RadarChart radarChart;

    public ClippedRadarChartRenderer(RadarChart chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
        this.radarChart = chart;
    }

    @Override
    public void drawData(Canvas c) {
        // Clip drawing to the chart circle to avoid any overshoot outside.
        c.save();
        MPPointF center = radarChart.getCenterOffsets();
        float radius = radarChart.getRadius();
        Path clip = new Path();
        clip.addCircle(center.x, center.y, radius, Path.Direction.CW);
        c.clipPath(clip);
        super.drawData(c);
        c.restore();
    }

    @Override
    public void drawHighlighted(Canvas c, com.github.mikephil.charting.highlight.Highlight[] indices) {
        // Ensure highlights also stay within the circle.
        c.save();
        MPPointF center = radarChart.getCenterOffsets();
        float radius = radarChart.getRadius();
        Path clip = new Path();
        clip.addCircle(center.x, center.y, radius, Path.Direction.CW);
        c.clipPath(clip);
        super.drawHighlighted(c, indices);
        c.restore();
    }
}

