package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PathEffect;
import android.graphics.RectF;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.buffer.BarBuffer;
import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.components.IMarker;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.interfaces.dataprovider.BarDataProvider;
import com.github.mikephil.charting.interfaces.datasets.IBarDataSet;
import com.github.mikephil.charting.renderer.BarChartRenderer;
import com.github.mikephil.charting.utils.MPPointD;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.mikephil.charting.utils.Transformer;
import com.github.mikephil.charting.utils.Utils;
import com.github.mikephil.charting.utils.ViewPortHandler;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

public class AtfleeBarChartRenderer extends BarChartRenderer {

    // 수직선 방향 선택: true → 위쪽으로 그리기, false → 아래쪽으로
    private static final boolean VERTICAL_TO_TOP = false;

    private RectF mBarShadowRectBuffer = new RectF();
    protected Float mRadius = 50.f;
    private final Paint crossPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

    public void setRadius(float radius) {
        mRadius = radius;
    }

    public AtfleeBarChartRenderer(BarDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
        crossPaint.setStyle(Paint.Style.STROKE);
    }

    @Override
    public void drawHighlighted(Canvas c, Highlight[] indices) {
        BarData data = mChart.getBarData();
        for (Highlight h : indices) {
            IBarDataSet raw = data.getDataSetByIndex(h.getDataSetIndex());
            if (raw == null || !raw.isHighlightEnabled()) continue;

            // 색상
            crossPaint.setColor(raw.getHighLightColor());

            // 굵기
            float strokeDp = 1f;
            try {
                Method m = raw.getClass().getMethod("getHighlightLineWidth");
                strokeDp = (Float) m.invoke(raw);
            } catch (Exception ignored) { /* ≤3.0.x */ }
            crossPaint.setStrokeWidth(Utils.convertDpToPixel(strokeDp));

            // α(투명도)
            int alpha = 255;
            try {
                Method mAlpha = raw.getClass().getMethod("getHighlightAlpha");
                alpha = (Integer) mAlpha.invoke(raw);
            } catch (Exception ignored) { /* fallback 255 */ }
            crossPaint.setAlpha(alpha);

            // dash
            try {
                Method mDash = raw.getClass().getMethod("getDashPathEffectHighlight");
                PathEffect pe = (PathEffect) mDash.invoke(raw);
                crossPaint.setPathEffect(pe);
            } catch (Exception ignored) { crossPaint.setPathEffect(null); }

            // 좌표 변환
            Transformer t = mChart.getTransformer(raw.getAxisDependency());
            MPPointD p = t.getPixelForValues(h.getX(), h.getY());

            // ② markerTop 계산
            float markerTop = (float) p.y;
            if (mChart instanceof BarLineChartBase<?> chartBase) {
              if (chartBase.isDrawMarkersEnabled()) {
                    IMarker marker = chartBase.getMarker();
                    if (marker != null) {
                        MPPointF off = marker.getOffsetForDrawingAtPoint((float) p.x, (float) p.y);
                        markerTop += off.y;                    // 보통 음수 → barTop보다 위
                    }
                }
            }
            // 차트 영역 밖이면 contentTop 으로 클램프
            if (markerTop < mViewPortHandler.contentTop())
                markerTop = mViewPortHandler.contentTop();

            h.setDraw((float) p.x, (float) p.y);

            float padPx = Utils.convertDpToPixel(10.0f);

            // 수직선
            float yStart, yEnd;
            if (VERTICAL_TO_TOP) {          // 위쪽 절반
                yStart = mViewPortHandler.contentTop();
                yEnd   = markerTop + padPx;
            } else {                        // 아래쪽 절반
                yStart = markerTop + padPx;
                yEnd   = mViewPortHandler.contentBottom();
            }
            c.drawLine((float) p.x, yStart, (float) p.x, yEnd, crossPaint);

            // 수평선
//            c.drawLine(mViewPortHandler.contentLeft(),  markerTop,
//               mViewPortHandler.contentRight(), markerTop, crossPaint);

            MPPointD.recycleInstance(p);
        }
    }

    protected void drawDataSet(Canvas c, IBarDataSet dataSet, int index) {
        Transformer trans = mChart.getTransformer(dataSet.getAxisDependency());

        mBarBorderPaint.setColor(dataSet.getBarBorderColor());
        mBarBorderPaint.setStrokeWidth(Utils.convertDpToPixel(dataSet.getBarBorderWidth()));

        final boolean drawBorder = dataSet.getBarBorderWidth() > 0.f;

        float phaseX = mAnimator.getPhaseX();
        float phaseY = mAnimator.getPhaseY();

        // draw the bar shadow before the values
        if (mChart.isDrawBarShadowEnabled()) {
            mShadowPaint.setColor(dataSet.getBarShadowColor());

            BarData barData = mChart.getBarData();

            final float barWidth = barData.getBarWidth();
            final float barWidthHalf = barWidth / 2.0f;
            float x;

            for (int i = 0, count = Math.min((int) (Math.ceil((float) (dataSet.getEntryCount()) * phaseX)), dataSet.getEntryCount());
                 i < count;
                 i++) {

                BarEntry e = dataSet.getEntryForIndex(i);

                x = e.getX();

                mBarShadowRectBuffer.left = x - barWidthHalf;
                mBarShadowRectBuffer.right = x + barWidthHalf;

                trans.rectValueToPixel(mBarShadowRectBuffer);

                if (!mViewPortHandler.isInBoundsLeft(mBarShadowRectBuffer.right))
                    continue;

                if (!mViewPortHandler.isInBoundsRight(mBarShadowRectBuffer.left))
                    break;

                mBarShadowRectBuffer.top = mViewPortHandler.contentTop();
                mBarShadowRectBuffer.bottom = mViewPortHandler.contentBottom();

                c.drawRoundRect(mBarShadowRectBuffer, mRadius, mRadius, mShadowPaint);
            }
        }

        // initialize the buffer
        BarBuffer buffer = mBarBuffers[index];
        buffer.setPhases(phaseX, phaseY);
        buffer.setDataSet(index);
        buffer.setInverted(mChart.isInverted(dataSet.getAxisDependency()));
        buffer.setBarWidth(mChart.getBarData().getBarWidth());

        buffer.feed(dataSet);

        trans.pointValuesToPixel(buffer.buffer);

        final boolean isSingleColor = dataSet.getColors().size() == 1;

        if (isSingleColor) {
            mRenderPaint.setColor(dataSet.getColor());
        }

        for (int j = 0; j < buffer.size(); j += 4) {

            if (!mViewPortHandler.isInBoundsLeft(buffer.buffer[j + 2]))
                continue;

            if (!mViewPortHandler.isInBoundsRight(buffer.buffer[j]))
                break;

            if (!isSingleColor) {
                // Set the color for the currently drawn value. If the index
                // is out of bounds, reuse colors.
                mRenderPaint.setColor(dataSet.getColor(j / 4));
            }

//            if (dataSet.getGradientColor() != null) {
//                GradientColor gradientColor = dataSet.getGradientColor();
//                mRenderPaint.setShader(
//                        new LinearGradient(
//                                buffer.buffer[j],
//                                buffer.buffer[j + 3],
//                                buffer.buffer[j],
//                                buffer.buffer[j + 1],
//                                gradientColor.getStartColor(),
//                                gradientColor.getEndColor(),
//                                android.graphics.Shader.TileMode.MIRROR));
//            }
//
//            if (dataSet.getGradientColors() != null) {
//                mRenderPaint.setShader(
//                        new LinearGradient(
//                                buffer.buffer[j],
//                                buffer.buffer[j + 3],
//                                buffer.buffer[j],
//                                buffer.buffer[j + 1],
//                                dataSet.getGradientColor(j / 4).getStartColor(),
//                                dataSet.getGradientColor(j / 4).getEndColor(),
//                                android.graphics.Shader.TileMode.MIRROR));
//            }


            BarEntry entry = dataSet.getEntryForIndex(j / 4);
            boolean isPositive = entry.getY() >= 0f;
            // round top corners for positive values, bottom corners for negatives
            float[] corners;
            if (isPositive) {
                corners = new float[]{
                        mRadius, mRadius,     // Top left radius in px
                        mRadius, mRadius,     // Top right radius in px
                        0f, 0f,               // Bottom right radius in px
                        0f, 0f                // Bottom left radius in px
                };
            } else {
                corners = new float[]{
                        0f, 0f,               // Top left radius in px
                        0f, 0f,               // Top right radius in px
                        mRadius, mRadius,     // Bottom right radius in px
                        mRadius, mRadius      // Bottom left radius in px
                };
            }

            final Path path = new Path();
            RectF rect = new RectF(buffer.buffer[j], buffer.buffer[j + 1], buffer.buffer[j + 2],
                    buffer.buffer[j + 3]);
            path.addRoundRect(rect, corners, Path.Direction.CW);
            c.drawPath(path, mRenderPaint);

//            c.drawRoundRect(buffer.buffer[j], buffer.buffer[j + 1], buffer.buffer[j + 2],
//                    buffer.buffer[j + 3], mRadius, mRadius/10.0f, mRenderPaint);
//
//            if (drawBorder) {
//                c.drawRoundRect(buffer.buffer[j], buffer.buffer[j + 1], buffer.buffer[j + 2],
//                        buffer.buffer[j + 3], mRadius, mRadius/2.0f, mBarBorderPaint);
//            }
        }
    }
}
