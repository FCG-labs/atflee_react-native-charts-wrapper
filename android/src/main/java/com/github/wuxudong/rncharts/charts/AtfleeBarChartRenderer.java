package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Path;
import android.graphics.RectF;

import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.buffer.BarBuffer;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.interfaces.dataprovider.BarDataProvider;
import com.github.mikephil.charting.interfaces.datasets.IBarDataSet;
import com.github.mikephil.charting.renderer.BarChartRenderer;
import com.github.mikephil.charting.utils.Transformer;
import com.github.mikephil.charting.utils.Utils;
import com.github.mikephil.charting.utils.ViewPortHandler;

public class AtfleeBarChartRenderer extends BarChartRenderer {

    private RectF mBarShadowRectBuffer = new RectF();
    protected Float mRadius = 50.f;

    public AtfleeBarChartRenderer(BarDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
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


            float[] corners = new float[]{
                    mRadius, mRadius,        // Top left radius in px
                    mRadius, mRadius,        // Top right radius in px
                    mRadius/2.0f, mRadius/2.0f,          // Bottom right radius in px
                    mRadius/2.0f, mRadius/2.0f           // Bottom left radius in px
            };

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
