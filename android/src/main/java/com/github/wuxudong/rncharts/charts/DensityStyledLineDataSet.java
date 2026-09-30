package com.github.wuxudong.rncharts.charts;

import androidx.annotation.Nullable;

import com.github.mikephil.charting.data.DataSet;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineDataSet;

import java.util.ArrayList;
import java.util.List;

/**
 * 보이는 점 개수로 점 반지름·선 굵기·중간 점 표시를 매 프레임 정하는 선 데이터셋.
 *
 * JS 는 기준값(densityStyle)만 한 번 넘기고, {@link NoClipLineChartRenderer} 가 그릴 때마다
 * 지금 보이는 구간(lowestVisibleX~highestVisibleX)으로 계산한다. JS 가 보이는 구간을 추측해
 * 조형을 데이터로 다시 보내면 화면과 비동기로만 맞아 탭 전환·핀치 때 어긋난 프레임이 생긴다.
 * densityStyle 이 없으면 LineDataSet 과 똑같이 동작한다. iOS 는 DensityStyledLineChartDataSet.swift.
 */
public class DensityStyledLineDataSet extends LineDataSet {

    /**
     * 식은 앳플리 「변화 전체」 화면의 JS 와 같다(ScaleFullChangesPage.tsx chartPointRadius · chartLineWidth ·
     * chartEndPointRadius, 걸쇠 30/28). 크기 단위는 dp.
     */
    public static final class DensityStyle {
        /** 이 개수가 보일 때의 점 반지름·선 굵기가 기준값이자 상한이다. */
        public float referenceCount = 7f;
        public float circleRadius = 4f;
        public float lineWidth = 3f;
        public float minLineWidth = 1.4f;
        public float lineWidthExponent = 0.6f;
        /** 보이는 점이 이 수를 넘으면 중간 점을 숨기고 보이는 양 끝 점만 그린다. */
        public float endsOnlyAbove = 30f;
        /** 숨긴 뒤에는 이 수를 넘는 동안 계속 숨긴다 — 경계에서 ±1 로 떨릴 때 점이 깜빡이지 않게. */
        public float endsOnlyReleaseAbove = 28f;
        public float endCircleRadiusRatio = 0.85f;
        public float minEndCircleRadius = 2f;

        public DensityStyle copy() {
            DensityStyle c = new DensityStyle();
            c.referenceCount = referenceCount;
            c.circleRadius = circleRadius;
            c.lineWidth = lineWidth;
            c.minLineWidth = minLineWidth;
            c.lineWidthExponent = lineWidthExponent;
            c.endsOnlyAbove = endsOnlyAbove;
            c.endsOnlyReleaseAbove = endsOnlyReleaseAbove;
            c.endCircleRadiusRatio = endCircleRadiusRatio;
            c.minEndCircleRadius = minEndCircleRadius;
            return c;
        }
    }

    @Nullable
    private DensityStyle densityStyle;
    private boolean endsOnlyLatched = false;

    // 한 프레임의 조형. 렌더러가 선을 그리기 전에 채우고, 같은 프레임의 점·값 라벨이 읽는다.
    // 반지름·굵기는 setCircleRadius · setLineWidth 로 바로 싣는다 — 중간 점을 숨기는 프레임에서는
    // circleRadius 가 곧 끝 점 반지름이라, 그리는 쪽은 어느 점을 그릴지만 가리면 된다.
    private boolean frameValid = false;
    private boolean frameEndsOnly = false;
    private int frameFirstVisibleIndex = -1;
    private int frameLastVisibleIndex = -1;
    private int frameVisibleCount = 0;

    public DensityStyledLineDataSet(List<Entry> yVals, String label) {
        super(yVals, label);
    }

    public void setDensityStyle(@Nullable DensityStyle style) {
        densityStyle = style;
        endsOnlyLatched = false;
        frameValid = false;
    }

    @Nullable
    public DensityStyle getDensityStyle() {
        return densityStyle;
    }

    public boolean hasDensityStyle() {
        return densityStyle != null;
    }

    /**
     * 보이는 x 구간으로 이번 프레임의 조형을 정하고 선 굵기·점 반지름에 싣는다.
     * 중간 점을 숨기는 프레임이면 circleRadius 는 끝 점 반지름이다.
     * 구간에 점이 하나도 없으면(점 사이 틈으로 확대) 앱 JS 와 같이 1개로 판정한다.
     */
    public void applyDensityStyle(float lowestVisibleX, float highestVisibleX) {
        DensityStyle style = densityStyle;
        if (style == null || getEntryCount() == 0 || !(highestVisibleX >= lowestVisibleX)) return;

        int first = getEntryIndex(lowestVisibleX, Float.NaN, DataSet.Rounding.UP);
        int last = getEntryIndex(highestVisibleX, Float.NaN, DataSet.Rounding.DOWN);
        Entry firstEntry = first >= 0 ? getEntryForIndex(first) : null;
        Entry lastEntry = last >= 0 ? getEntryForIndex(last) : null;
        boolean visible = firstEntry != null && lastEntry != null && last >= first
                && firstEntry.getX() >= lowestVisibleX - 1e-4f
                && lastEntry.getX() <= highestVisibleX + 1e-4f;
        int count = visible ? last - first + 1 : 1;
        double ratio = (count > 1 && style.referenceCount > 1f)
                ? Math.sqrt((style.referenceCount - 1.0) / (count - 1.0))
                : 1.0;
        double radius = Math.min(style.circleRadius, style.circleRadius * ratio);
        double width = Math.min(style.lineWidth,
                Math.max(style.minLineWidth, style.lineWidth * Math.pow(ratio, style.lineWidthExponent)));
        boolean endsOnly = endsOnlyLatched
                ? count > style.endsOnlyReleaseAbove
                : count > style.endsOnlyAbove;
        endsOnlyLatched = endsOnly;
        double endRadius = Math.max(style.minEndCircleRadius,
                style.circleRadius * style.endCircleRadiusRatio * (style.lineWidth > 0f ? width / style.lineWidth : 1.0));

        // LineDataSet 은 dp 를 받아 px 로 바꿔 둔다. 반지름은 1 미만을 거부(직전 값이 남는다)하므로 1 에서 멈춘다.
        setLineWidth((float) width);
        setCircleRadius(Math.max(1f, (float) (endsOnly ? endRadius : radius)));

        frameEndsOnly = endsOnly;
        frameFirstVisibleIndex = visible ? first : -1;
        frameLastVisibleIndex = visible ? last : -1;
        frameVisibleCount = count;
        frameValid = true;
    }

    /** 이번 프레임에 index 의 점을 그리는가 — 중간 점을 숨기는 프레임이면 보이는 양 끝만. */
    public boolean shouldDrawCircleAt(int index) {
        if (densityStyle == null || !frameValid || !frameEndsOnly) return true;
        return index == frameFirstVisibleIndex || index == frameLastVisibleIndex;
    }

    public boolean isFrameEndsOnly() {
        return densityStyle != null && frameValid && frameEndsOnly;
    }

    public int getFrameVisibleCount() {
        return frameValid ? frameVisibleCount : 0;
    }

    @Override
    public DataSet<Entry> copy() {
        List<Entry> entries = new ArrayList<>();
        for (int i = 0; i < mValues.size(); i++) {
            entries.add(mValues.get(i).copy());
        }
        DensityStyledLineDataSet copied = new DensityStyledLineDataSet(entries, getLabel());
        copy(copied);
        copied.setDensityStyle(densityStyle != null ? densityStyle.copy() : null);
        return copied;
    }
}
