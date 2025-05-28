package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import android.os.Build;
import android.text.Layout;
import android.text.StaticLayout;
import android.text.TextPaint;

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
  protected void drawLabel(Canvas c, String formattedLabel, float x, float y, MPPointF anchor, float angleDegrees) {
    Paint paint = mAxisLabelPaint;
    paint.setTextAlign(Paint.Align.CENTER);

    // 1) label을 줄바꿈(\n) 기준으로 분할
    String[] lines = formattedLabel.split("\\n");

    // 2) 각 줄을 차례로 그림
    float lineHeight = -paint.ascent() + paint.descent();

    // anchor.y가 baseline offset이므로, baseline 위치 보정
    float yOffset = y;

    // 위아래 중앙 정렬하려면:
     float totalHeight = lineHeight * lines.length;
     yOffset = y - totalHeight / 2 + ( -paint.ascent() );

    for (String line : lines) {
      c.drawText(line, x, yOffset, paint);
      yOffset += lineHeight;
    }
  }
}
