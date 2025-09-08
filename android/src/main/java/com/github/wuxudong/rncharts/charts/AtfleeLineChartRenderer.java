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
    protected void drawValue(Canvas c, String valueText, float x, float y, int color) {
        // Clamp baseline so that the drawn text box (using ascent/descent) stays inside content rect
        final float contentTop = mViewPortHandler.contentTop();
        final float contentBottom = mViewPortHandler.contentBottom();

        Paint.FontMetrics fm = mValuePaint.getFontMetrics();
        float textTop = y + fm.ascent;     // ascent is negative
        float textBottom = y + fm.descent; // descent is positive

        if (textTop < contentTop) {
            float dy = contentTop - textTop;
            y += dy;
        } else if (textBottom > contentBottom) {
            float dy = textBottom - contentBottom;
            y -= dy;
        }

        super.drawValue(c, valueText, x, y, color);
    }
}

