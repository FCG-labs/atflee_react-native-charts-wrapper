package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.util.Log;
import java.util.ArrayList;
import java.util.List;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.interfaces.dataprovider.LineDataProvider;
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;
import com.github.mikephil.charting.renderer.LineChartRenderer;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.interfaces.datasets.ILineScatterCandleRadarDataSet;
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

    private static final String TAG = "RNCharts-LineLabel";
    // Verbose logging only around the top-edge scenario to keep noise low
    private static final float TOP_EPS_DP = 2f;
    // Slightly tighten vertical padding when drawing label ABOVE the circle
    // (Android felt a bit too far compared to desired UI)
    private static final float LABEL_OFFSET_SCALE_ABOVE = 0.85f; // 85% of previous spacing

    private static class PendingLabel {
        final String text; final float x; final float y; final int color;
        PendingLabel(String t, float x, float y, int c){ this.text=t; this.x=x; this.y=y; this.color=c; }
    }
    private final List<PendingLabel> pendingTopLabels = new ArrayList<>();

    public NoClipLineChartRenderer(LineDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
    }

    @Override
    public void drawValues(Canvas c) {
        LineDataProvider provider = mChart;
        if (provider == null) return;
        LineData lineData = provider.getLineData();
        if (lineData == null) return;

        boolean allowed = isDrawingValuesAllowed(provider);
        if (!allowed) {
            Log.i(TAG, "drawValues skipped: not allowed for current zoom/entryCount");
            return;
        }

        final float phaseY = mAnimator.getPhaseY();

        final float lowestVisibleX = provider.getLowestVisibleX();
        final float highestVisibleX = provider.getHighestVisibleX();

        pendingTopLabels.clear();
        Log.i(TAG, String.format("drawValues begin: sets=%d phaseY=%.2f visX=[%.2f..%.2f]", lineData.getDataSetCount(), phaseY, lowestVisibleX, highestVisibleX));
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
                // draw above the point with slightly reduced gap
                float yAbove = (float) pt.y - (valOffset * LABEL_OFFSET_SCALE_ABOVE) - textHeight;
                float y;

                float contentTop = mViewPortHandler.contentTop();
                float contentBottom = mViewPortHandler.contentBottom();
                boolean drawBelow = yAbove < contentTop; // current policy

                if (drawBelow) {
                    // not enough room above → draw below instead
                    y = (float) pt.y + valOffset + textHeight;
                    if (y > contentBottom) {
                        // clamp to bottom inside content if still overflowing
                        y = contentBottom - 2f;
                    }
                } else {
                    y = yAbove;
                }

                // keep text horizontally within content rect to avoid clipping by view bounds
                float half = textWidth / 2f;
                if (x - half < mViewPortHandler.contentLeft()) x = mViewPortHandler.contentLeft() + half;
                if (x + half > mViewPortHandler.contentRight()) x = mViewPortHandler.contentRight() - half;

                // Debug logging for top-edge cases to diagnose missing labels
                float topEpsPx = Utils.convertDpToPixel(TOP_EPS_DP);
                float axisMax = Float.NaN;
                if (provider instanceof BarLineChartBase) {
                    BarLineChartBase<?> bl = (BarLineChartBase<?>) provider;
                    axisMax = (dataSet.getAxisDependency() == YAxis.AxisDependency.LEFT)
                            ? bl.getAxisLeft().getAxisMaximum()
                            : bl.getAxisRight().getAxisMaximum();
                } else if (provider instanceof LineChart) {
                    LineChart lc = (LineChart) provider;
                    axisMax = (dataSet.getAxisDependency() == YAxis.AxisDependency.LEFT)
                            ? lc.getAxisLeft().getAxisMaximum()
                            : lc.getAxisRight().getAxisMaximum();
                }
                boolean nearAxisMax = Math.abs(axisMax - e.getY()) <= 1e-4;
                boolean nearTopEdge = (yAbove < contentTop + topEpsPx) || (float) pt.y <= contentTop + topEpsPx;
                boolean deferDraw = false;
                if (nearAxisMax || nearTopEdge) {
                    int color = dataSet.getValueTextColor(j);
                    Log.d(TAG, String.format(
                            "i=%d j=%d x=%.2f yVal=%.2f ptY=%.2f yAbove=%.2f chosenY=%.2f cTop=%.2f cBot=%.2f valOffset=%d txtH=%.2f drawBelow=%s axisMax=%.2f phaseY=%.2f text='%s' color=#%08X",
                            i, j, e.getX(), e.getY(), pt.y, yAbove, y, contentTop, contentBottom, valOffset, textHeight, String.valueOf(drawBelow), axisMax, phaseY, text, color
                    ));
                    // save for redraw on top in drawExtras
                    pendingTopLabels.add(new PendingLabel(text, x, y, color));
                    deferDraw = true; // avoid double drawing; draw later in overlay
                }

                if (!deferDraw) {
                    int color = dataSet.getValueTextColor(j);
                    drawValue(c, text, x, y, color);
                }

                MPPointD.recycleInstance(pt);
            }
        }
    }

    /** Draw pending top-edge labels after all renderers have drawn, with no outline. */
    public void drawTopLabelsOverlay(Canvas c) {
        if (pendingTopLabels.isEmpty()) return;
        for (PendingLabel pl : pendingTopLabels) {
            drawValue(c, pl.text, pl.x, pl.y, pl.color);
        }
        pendingTopLabels.clear();
    }

    // Clamp highlight Y to content so markers are eligible to render
    @Override
    public void drawHighlighted(Canvas c, Highlight[] indices) {
        LineDataProvider provider = mChart;
        if (provider == null) return;
        LineData lineData = provider.getLineData();
        if (lineData == null) return;

        final float phaseY = mAnimator.getPhaseY();
        final float cTop = mViewPortHandler.contentTop();
        final float cBot = mViewPortHandler.contentBottom();

        for (Highlight high : indices) {
            ILineDataSet set = lineData.getDataSetByIndex(high.getDataSetIndex());
            if (set == null || !set.isHighlightEnabled()) continue;

            Entry e = set.getEntryForXValue(high.getX(), high.getY());
            if (e == null) continue;
            if (!isInBoundsX(e, set)) continue;

            MPPointD pix = provider.getTransformer(set.getAxisDependency())
                    .getPixelForValues(e.getX(), e.getY() * phaseY);
            float px = (float) pix.x;
            float py = (float) pix.y;
            if (py < cTop) py = cTop; else if (py > cBot) py = cBot;
            high.setDraw(px, py);

            // draw the highlight lines ourselves so they align with clamped point
            drawHighlightLines(c, px, py, (ILineScatterCandleRadarDataSet) set);
            MPPointD.recycleInstance(pix);
        }
    }

    // Draw circles without Y in-bounds rejection so edge points remain visible
    @Override
    public void drawExtras(Canvas c) {
        super.drawExtras(c);
        LineDataProvider provider = mChart;
        if (provider == null) return;
        LineData lineData = provider.getLineData();
        if (lineData == null) return;

        final float phaseX = mAnimator.getPhaseX();
        final float phaseY = mAnimator.getPhaseY();

        for (int i = 0; i < lineData.getDataSetCount(); i++) {
            ILineDataSet dataSet = lineData.getDataSetByIndex(i);
            if (dataSet == null || !dataSet.isVisible() || !dataSet.isDrawCirclesEnabled()) continue;

            final int entryCount = Math.min((int) Math.ceil(dataSet.getEntryCount() * phaseX), dataSet.getEntryCount());
            for (int j = 0; j < entryCount; j++) {
                Entry e = dataSet.getEntryForIndex(j);
                if (e == null) continue;
                MPPointD pt = provider.getTransformer(dataSet.getAxisDependency())
                        .getPixelForValues(e.getX(), e.getY() * phaseY);

                if (!mViewPortHandler.isInBoundsRight((float) pt.x)) { MPPointD.recycleInstance(pt); break; }
                if (!mViewPortHandler.isInBoundsLeft((float) pt.x))  { MPPointD.recycleInstance(pt); continue; }

                float x = (float) pt.x;
                float y = (float) pt.y;
                if (y < mViewPortHandler.contentTop()) y = mViewPortHandler.contentTop();
                else if (y > mViewPortHandler.contentBottom()) y = mViewPortHandler.contentBottom();

                float r = dataSet.getCircleRadius();
                mRenderPaint.setStyle(Paint.Style.FILL);
                int circleColorCount = dataSet.getCircleColorCount();
                int circleIdx = circleColorCount > 0 ? (j % circleColorCount) : 0;
                int circleColor = circleColorCount > 0 ? dataSet.getCircleColor(circleIdx) : dataSet.getColor();
                mRenderPaint.setColor(circleColor);
                c.drawCircle(x, y, r, mRenderPaint);

                if (dataSet.isDrawCircleHoleEnabled() && dataSet.getCircleHoleRadius() > 0f) {
                    float hr = dataSet.getCircleHoleRadius();
                    Integer hole = dataSet.getCircleHoleColor();
                    if (hole != null) {
                        mRenderPaint.setColor(hole);
                        c.drawCircle(x, y, hr, mRenderPaint);
                    }
                }

                MPPointD.recycleInstance(pt);
            }
        }
    }
}
