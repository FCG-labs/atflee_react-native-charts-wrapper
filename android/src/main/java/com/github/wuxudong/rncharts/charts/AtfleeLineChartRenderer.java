package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Paint;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.renderer.LineChartRenderer;
import com.github.mikephil.charting.utils.ViewPortHandler;
import com.github.mikephil.charting.interfaces.dataprovider.LineDataProvider;

/**
 * A LineChartRenderer that clamps value label drawing within the content rect
 * to avoid top-edge clipping due to floating-point rounding near axis maximum.
 */
public class AtfleeLineChartRenderer extends LineChartRenderer {

    public AtfleeLineChartRenderer(LineDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
    }

    @Override
    public void drawValue(Canvas c, String valueText, float x, float y, int color) {
        // Prefer drawing labels above the point for aesthetics, then clamp inside content rect.
        final float contentTop = mViewPortHandler.contentTop();
        final float contentBottom = mViewPortHandler.contentBottom();

        Paint.FontMetrics fm = mValuePaint.getFontMetrics();
        float textHeight = fm.descent - fm.ascent;

        // Upward bias: move baseline up by ~60% of text height so labels tend to appear above the point
        y -= (textHeight * 0.6f);

        float textTop = y + fm.ascent;     // ascent is negative
        float textBottom = y + fm.descent; // descent is positive

        // Top clamp
        if (textTop < contentTop) {
            float dy = contentTop - textTop;
            y += dy;
            textBottom += dy;
        }
        // Bottom clamp
        if (textBottom > contentBottom) {
            float dy = textBottom - contentBottom;
            y -= dy;
        }

        super.drawValue(c, valueText, x, y, color);
    }
}
