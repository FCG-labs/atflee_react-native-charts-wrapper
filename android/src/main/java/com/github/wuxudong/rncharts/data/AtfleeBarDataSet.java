package com.github.wuxudong.rncharts.data;

import android.graphics.DashPathEffect;

import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;

import java.util.List;

/**
 * BarDataSet 서브클래스 — MPAndroidChart 의 BarDataSet 에는
 * `getHighlightLineWidth` / `getDashPathEffectHighlight` 등이 존재하지 않아
 * AtfleeBarChartRenderer 의 reflection 호출이 silently fail 하고
 * 기본값(1dp solid) 으로 highlight 라인이 그려진다.
 *
 * 이 서브클래스는 LineScatterCandleRadarDataSet 와 동일한 시그니처의
 * 메서드를 추가해, JS 의 `highlightLineWidth` / `dashedHighlightLine`
 * prop 이 BarChart 에서도 동작하도록 한다.
 */
public class AtfleeBarDataSet extends BarDataSet {

    private float mHighlightLineWidth = 0.5f;
    private DashPathEffect mHighlightDashPathEffect = null;

    public AtfleeBarDataSet(List<BarEntry> yVals, String label) {
        super(yVals, label);
    }

    public float getHighlightLineWidth() {
        return mHighlightLineWidth;
    }

    public void setHighlightLineWidth(float widthDp) {
        // AtfleeBarChartRenderer 가 반환값을 DP 로 보고 다시 convertDpToPixel 적용하므로,
        // 여기서는 변환 없이 raw DP 값을 저장한다 (LineScatter 와 다른 컨벤션).
        mHighlightLineWidth = widthDp;
    }

    public DashPathEffect getDashPathEffectHighlight() {
        return mHighlightDashPathEffect;
    }

    public void enableDashedHighlightLine(float lineLength, float spaceLength, float phase) {
        mHighlightDashPathEffect = new DashPathEffect(new float[]{lineLength, spaceLength}, phase);
    }

    public void disableDashedHighlightLine() {
        mHighlightDashPathEffect = null;
    }

    public boolean isDashedHighlightLineEnabled() {
        return mHighlightDashPathEffect != null;
    }
}
