package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Paint;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.renderer.LineChartRenderer;
import com.github.mikephil.charting.utils.ViewPortHandler;
import com.github.mikephil.charting.interfaces.dataprovider.LineDataProvider;
import com.github.mikephil.charting.utils.Utils;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.mikephil.charting.utils.Transformer;

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

        // Remember original baseline (usually already above the point in MPAndroidChart)
        final float yOriginal = y;

        // Upward bias: move baseline up so labels tend to appear above the point
        y -= (textHeight * 0.6f);
        // Extra visual gap from the point
        y -= Utils.convertDpToPixel(4f);

        float textTop = y + fm.ascent;     // ascent is negative
        float textBottom = y + fm.descent; // descent is positive

        // Top clamp: ensure the label box sits fully inside the content area.
        // Note: We do not cap by yOriginal here; doing so can leave textTop still above contentTop
        // and result in the label being clipped when large extraOffsets.top are applied.
        if (textTop < contentTop) {
            float dy = contentTop - textTop;
            y += dy; // move down just enough to fit
            textBottom = y + fm.descent;
        }
        // Bottom clamp
        if (textBottom > contentBottom) {
            float dy = textBottom - contentBottom;
            y -= dy;
        }

        super.drawValue(c, valueText, x, y, color);
    }

    @Override
    public void drawValues(Canvas c) {
        if (!isDrawingValuesAllowed(mChart))
            return;

        final float phaseX = mAnimator.getPhaseX();
        final float phaseY = mAnimator.getPhaseY();

        LineData lineData = mChart.getLineData();
        if (lineData == null)
            return;

        for (int i = 0; i < lineData.getDataSetCount(); i++) {
            ILineDataSet dataSet = lineData.getDataSetByIndex(i);

            if (dataSet == null || !shouldDrawValues(dataSet) || dataSet.getEntryCount() == 0)
                continue;

            applyValueTextStyle(dataSet);

            mXBounds.set(mChart, dataSet);

            Transformer trans = mChart.getTransformer(dataSet.getAxisDependency());
            float[] positions = trans.generateTransformedValuesLine(
                    dataSet, phaseX, phaseY, mXBounds.min, mXBounds.max);

            for (int j = 0; j < positions.length; j += 2) {
                final float x = positions[j];
                if (!mViewPortHandler.isInBoundsRight(x))
                    break;
                if (!mViewPortHandler.isInBoundsLeft(x))
                    continue;

                final int entryIndex = j / 2 + mXBounds.min;
                if (entryIndex < 0 || entryIndex >= dataSet.getEntryCount())
                    continue;

                Entry e = dataSet.getEntryForIndex(entryIndex);
                float baseY = positions[j + 1];

                // Compute label baseline with the same bias/clamp used in drawValue
                Paint.FontMetrics fm = mValuePaint.getFontMetrics();
                float textHeight = fm.descent - fm.ascent;
                float yLabel = baseY - (textHeight * 0.6f) - Utils.convertDpToPixel(4f);

                final float contentTop = mViewPortHandler.contentTop();
                final float contentBottom = mViewPortHandler.contentBottom();
                float textTop = yLabel + fm.ascent;
                float textBottom = yLabel + fm.descent;
                if (textTop < contentTop) {
                    yLabel += (contentTop - textTop);
                    textBottom = yLabel + fm.descent;
                }
                if (textBottom > contentBottom) {
                    yLabel -= (textBottom - contentBottom);
                }

                if (!mViewPortHandler.isInBoundsY(yLabel))
                    continue;

                int color = dataSet.getValueTextColor(entryIndex);
                String label = dataSet.getValueFormatter().getPointLabel(e);
                drawValue(c, label, x, yLabel, color);
            }
        }
    }
}
