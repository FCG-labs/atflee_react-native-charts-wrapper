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

    // 라인·마커 여백(dp). iOS RoundedBarChartRenderer.markerPadDp(=10.0) 와 동일한 SSOT 값.
    private static final float MARKER_PAD_DP = 10.0f;

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

            // 색상 — highlightColor 의 alpha 채널을 SSOT 로 사용 (LineChart 동작과 일치).
            // 과거 코드에서 getHighlightAlpha 를 reflection 으로 읽어 setAlpha(...) 로 덮어썼는데,
            // 실제 메서드명은 getHighLightAlpha (대문자 L) 라서 reflection 이 항상 실패 → alpha=255 로
            // 덮어쓰여 JS 가 rgba(..., 0.4) 로 인코딩한 alpha 가 무효화되는 버그가 있었다.
            crossPaint.setColor(raw.getHighLightColor());

            // 굵기
            float strokeDp = 1f;
            try {
                Method m = raw.getClass().getMethod("getHighlightLineWidth");
                strokeDp = (Float) m.invoke(raw);
            } catch (Exception ignored) { /* ≤3.0.x */ }
            crossPaint.setStrokeWidth(Utils.convertDpToPixel(strokeDp));

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
            // off.y(보통 음수 → barTop 위)와 마커 여백(pad)을 contentTop 클램프 "이전"에 함께 더한다.
            // iOS RoundedBarChartRenderer 와 동일: markerY = pt.y + off.y + pad → 그 다음 클램프.
            // 과거에는 pad 를 클램프 "이후" yStart 에서 더해(fixedOnTop 시 markerTop 이 contentTop 으로
            // 클램프된 뒤 pad 가 다시 더해짐) 점선이 contentTop + pad 부터 시작 → 상단 고정 알약과
            // 점선 사이에 pad(10dp)만큼 빈틈이 생기는 AOS 전용 회귀가 있었다. 클램프 전에 더하면
            // 클램프가 pad 를 흡수해, iOS 처럼 점선이 contentTop 부터 시작하여 알약과 자연스럽게 이어진다.
            float markerTop = (float) p.y;
            if (mChart instanceof BarLineChartBase) {
              if (((BarLineChartBase) mChart).isDrawMarkersEnabled()) {
                    IMarker marker = ((BarLineChartBase) mChart).getMarker();
                    if (marker != null) {
                        MPPointF off = marker.getOffsetForDrawingAtPoint((float) p.x, (float) p.y);
                        markerTop += off.y + Utils.convertDpToPixel(MARKER_PAD_DP);
                    }
                }
            }
            // 차트 영역 밖이면 contentTop 으로 클램프
            if (markerTop < mViewPortHandler.contentTop())
                markerTop = mViewPortHandler.contentTop();

            h.setDraw((float) p.x, (float) p.y);

            // 수직선 (pad 는 markerTop 에 이미 포함됨)
            float yStart, yEnd;
            if (VERTICAL_TO_TOP) {          // 위쪽 절반
                yStart = mViewPortHandler.contentTop();
                yEnd   = markerTop;
            } else {                        // 아래쪽 절반
                yStart = markerTop;
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
