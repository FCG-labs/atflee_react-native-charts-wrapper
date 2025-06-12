package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.graphics.Paint;
import java.lang.Math;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.renderer.XAxisRenderer;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.mikephil.charting.utils.Transformer;
import com.github.mikephil.charting.utils.ViewPortHandler;

public class MultilineXAxisRenderer extends XAxisRenderer {
  public MultilineXAxisRenderer(ViewPortHandler viewPortHandler, XAxis xAxis, Transformer trans) {
    super(viewPortHandler, xAxis, trans);
  }

  @Override
  protected void computeSize() {
    super.computeSize();

    String longest = mXAxis.getLongestLabel();
    if (longest == null || !longest.contains("\n")) {
      return;
    }

    String[] lines = longest.split("\\n");
    int lineCount = lines.length;
    if (lineCount <= 1) {
      return;
    }

    float maxLineWidth = 0f;
    for (String line : lines) {
      maxLineWidth = Math.max(maxLineWidth, mAxisLabelPaint.measureText(line));
    }

    Paint.FontMetrics fm = mAxisLabelPaint.getFontMetrics();
    float lineHeight = fm.descent - fm.ascent - 1f;
    float labelHeight = lineCount * lineHeight + (lineCount - 1) * fm.leading;

    float angle = mXAxis.getLabelRotationAngle();
    double rad = Math.toRadians(angle);
    float sin = (float) Math.abs(Math.sin(rad));
    float cos = (float) Math.abs(Math.cos(rad));
    float rotatedWidth = maxLineWidth * cos + labelHeight * sin;
    float rotatedHeight = maxLineWidth * sin + labelHeight * cos;

    mXAxis.mLabelWidth = Math.round(maxLineWidth + mXAxis.getXOffset() * 3.5f);
    mXAxis.mLabelHeight = Math.round(labelHeight);
    mXAxis.mLabelRotatedWidth = Math.round(rotatedWidth + mXAxis.getXOffset() * 3.5f);
    mXAxis.mLabelRotatedHeight = Math.round(rotatedHeight);
  }

  @Override
  protected void drawLabel(Canvas c, String formattedLabel, float x, float y, MPPointF anchor, float angleDegrees) {
    Paint paint = mAxisLabelPaint;
    paint.setTextAlign(Paint.Align.CENTER);

    // 1) 폰트 메트릭 전체 높이 계산
    Paint.FontMetrics fm = paint.getFontMetrics();
    float textHeight = fm.descent - fm.ascent - 1;

    // 2) lines 배열
    String[] lines = formattedLabel.split("\\n");
    int lineCount = lines.length;

    // 3) 전체 멀티라인 높이
    float totalHeight = lineCount * textHeight + (lineCount - 1) * paint.getFontMetrics().leading;

    // 4) anchor.y 반영: 라벨의 기준점 보정
    float yOffset = y - totalHeight * anchor.y - fm.ascent;

    // 5) 회전 적용
    c.save();
    c.translate(x, yOffset);
    if (angleDegrees != 0f) {
      c.rotate(angleDegrees, 0, totalHeight * anchor.y);
    }

    // 6) 각 라인 렌더
    float lineY = 0f;
    for (String line : lines) {
      c.drawText(line, 0f, lineY - fm.ascent, paint);
      lineY += textHeight + fm.leading;
    }
    c.restore();
  }
}
