package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Paint;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.interfaces.dataprovider.LineChartDataProvider;
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;
import com.github.mikephil.charting.renderer.LineChartRenderer;
import com.github.mikephil.charting.utils.MPPointD;
import com.github.mikephil.charting.utils.Utils;
import com.github.mikephil.charting.utils.ViewPortHandler;

/**
 * Custom line renderer that avoids dropping value labels when points sit on the
 * top content edge. If there is no room above the point, the value label is
 * drawn below the point instead. Also skips the Y in-bounds check so values can
 * render inside the chart's extra offset region.
 */
public class NoClipLineChartRenderer extends LineChartRenderer {

    public NoClipLineChartRenderer(LineChartDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
    }

    @Override
    public void drawValues(Canvas c) {
        LineChartDataProvider provider = mChart;
        if (provider == null) return;
        LineData lineData = provider.getLineData();
        if (lineData == null) return;

        if (!isDrawingValuesAllowed(provider)) return;

        final float phaseY = mAnimator.getPhaseY();

        final float lowestVisibleX = provider.getLowestVisibleX();
        final float highestVisibleX = provider.getHighestVisibleX();

        for (int i = 0; i < lineData.getDataSetCount(); i++) {
            ILineDataSet dataSet = lineData.getDataSetByIndex(i);
            if (dataSet == null || !dataSet.isVisible() || !dataSet.isDrawValuesEnabled()) continue;

            // style
            applyValueTextStyle(dataSet);

            final float circleRadius = dataSet.getCircleRadius();
            int valOffset = (int) (circleRadius * 1.75f);
            if (!dataSet.isDrawCirclesEnabled()) {
                valOffset = valOffset / 2;
            }

            for (int j = 0; j < dataSet.getEntryCount(); j++) {
                Entry e = dataSet.getEntryForIndex(j);
                if (e == null) continue;

                // skip outside current viewport X range
                if (e.getX() < lowestVisibleX || e.getX() > highestVisibleX) continue;

                MPPointD pt = provider.getTransformer(dataSet.getAxisDependency())
                        .getPixelForValues(e.getX(), e.getY() * phaseY);

                if (!mViewPortHandler.isInBoundsRight((float) pt.x)) {
                    MPPointD.recycleInstance(pt);
                    break;
                }
                if (!mViewPortHandler.isInBoundsLeft((float) pt.x)) {
                    MPPointD.recycleInstance(pt);
                    continue;
                }

                String text = dataSet.getValueFormatter().getFormattedValue(e.getY());

                // measure text
                float textWidth = Utils.calcTextWidth(mValuePaint, text);
                Paint.FontMetrics fm = mValuePaint.getFontMetrics();
                float textHeight = fm.descent - fm.ascent;

                float x = (float) pt.x;
                float yAbove = (float) pt.y - valOffset - textHeight; // draw above the point normally
                float y;

                if (yAbove < mViewPortHandler.contentTop()) {
                    // not enough room above → draw below instead
                    y = (float) pt.y + valOffset + textHeight;
                    if (y > mViewPortHandler.contentBottom()) {
                        // clamp to bottom inside content if still overflowing
                        y = mViewPortHandler.contentBottom() - 2f;
                    }
                } else {
                    y = yAbove;
                }

                // keep text horizontally within content rect to avoid clipping by view bounds
                float half = textWidth / 2f;
                if (x - half < mViewPortHandler.contentLeft()) x = mViewPortHandler.contentLeft() + half;
                if (x + half > mViewPortHandler.contentRight()) x = mViewPortHandler.contentRight() - half;

                drawValue(c, text, x, y, dataSet.getValueTextColor(j));

                MPPointD.recycleInstance(pt);
            }
        }
    }
}

