package com.github.wuxudong.rncharts.charts.helpers;

import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.view.View.OnLayoutChangeListener;
import android.widget.TextView;

import com.github.mikephil.charting.data.ChartData;

import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.formatter.ValueFormatter;

/** Helper for fixed edge labels overlayed on the chart. */
public class EdgeLabelHelper {
    private static final float PADDING_DP_LEFT = 8f;
    private static final float PADDING_DP_RIGHT = 26f;
    private static final float PADDING_DP_TOP = 16f;
    private static java.util.WeakHashMap<BarLineChartBase, Boolean> enabledMap = new java.util.WeakHashMap<>();
    private static java.util.WeakHashMap<BarLineChartBase, float[]> baseOffsets = new java.util.WeakHashMap<>();
    private static java.util.WeakHashMap<BarLineChartBase, View.OnLayoutChangeListener> layoutListeners = new java.util.WeakHashMap<>();
    private static String leftTag(Chart chart) {
        return "edgeLabelLeft-" + chart.getId();
    }
    private static String rightTag(Chart chart) {
        return "edgeLabelRight-" + chart.getId();
    }

    private static int px(View view, float dp) {
        return Math.round(TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP,
                dp,
                view.getResources().getDisplayMetrics()));
    }

    public static void setEnabled(BarLineChartBase chart, boolean enabled) {
        enabledMap.put(chart, enabled);
        ViewGroup parent = (ViewGroup) chart.getParent();
        if (parent == null) {
            chart.addOnAttachStateChangeListener(new View.OnAttachStateChangeListener() {
                @Override public void onViewAttachedToWindow(View view) {
                    chart.removeOnAttachStateChangeListener(this);
                    setEnabled(chart, enabled);
                }
                @Override public void onViewDetachedFromWindow(View view) {}
            });
            return;
        }

        TextView left = parent.findViewWithTag(leftTag(chart));
        TextView right = parent.findViewWithTag(rightTag(chart));
        OnLayoutChangeListener listener = layoutListeners.get(chart);
        if (!enabled) {
            if (left != null) parent.removeView(left);
            if (right != null) parent.removeView(right);
            if (listener != null) {
                chart.removeOnLayoutChangeListener(listener);
                layoutListeners.remove(chart);
            }
            applyPadding(chart);
            return;
        }

        if (left == null) {
            left = new TextView(chart.getContext());
            left.setClickable(false);
            left.setFocusable(false);
            parent.addView(left);
            left.setTag(leftTag(chart));
        }
        if (right == null) {
            right = new TextView(chart.getContext());
            right.setClickable(false);
            right.setFocusable(false);
            parent.addView(right);
            right.setTag(rightTag(chart));
        }

        if (listener == null) {
            final BarLineChartBase c = chart;
            listener = new OnLayoutChangeListener() {
                @Override
                public void onLayoutChange(View v, int leftL, int topL, int rightL, int bottomL,
                                           int oldLeft, int oldTop, int oldRight, int oldBottom) {
                    if (leftL != oldLeft || topL != oldTop || rightL != oldRight || bottomL != oldBottom) {
                        reposition(c);
                    }
                }
            };
            chart.addOnLayoutChangeListener(listener);
            layoutListeners.put(chart, listener);
        }

        style(chart);
        reposition(chart);
        update(chart, chart.getLowestVisibleX(), chart.getHighestVisibleX());
        applyPadding(chart);
    }

    private static void reposition(BarLineChartBase chart) {
        ViewGroup parent = (ViewGroup) chart.getParent();
        if (parent == null) return;
        TextView left = parent.findViewWithTag(leftTag(chart));
        TextView right = parent.findViewWithTag(rightTag(chart));
        if (left == null || right == null) return;

        int widthSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
        int heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
        left.measure(widthSpec, heightSpec);
        right.measure(widthSpec, heightSpec);

        int leftW = left.getMeasuredWidth();
        int leftH = left.getMeasuredHeight();
        int rightW = right.getMeasuredWidth();
        int rightH = right.getMeasuredHeight();

        int chartLeft = chart.getLeft();
        int chartRight = chart.getRight();
        int chartBottom = chart.getBottom();

        int padLeft = px(chart, PADDING_DP_LEFT);
        int padRight = px(chart, PADDING_DP_RIGHT);
        int padTop = px(chart, PADDING_DP_TOP);

        left.layout(chartLeft + padLeft, chartBottom - leftH - padTop, chartLeft + padLeft + leftW, chartBottom);
        right.layout(chartRight - rightW - padRight, chartBottom - rightH - padTop, chartRight - padRight, chartBottom);

        left.bringToFront();
        right.bringToFront();
        applyPadding(chart);
    }

    private static void style(BarLineChartBase chart) {
        ViewGroup parent = (ViewGroup) chart.getParent();
        if (parent == null) return;
        TextView left = parent.findViewWithTag(leftTag(chart));
        TextView right = parent.findViewWithTag(rightTag(chart));
        if (left == null || right == null) return;

        XAxis axis = chart.getXAxis();
        int color = axis.getTextColor();
        float size = axis.getTextSize();
        left.setTextColor(color);
        right.setTextColor(color);
        left.setTextAlignment(TextView.TEXT_ALIGNMENT_CENTER);
        right.setTextAlignment(TextView.TEXT_ALIGNMENT_CENTER);
        right.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
        left.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
        right.setTextSize(TypedValue.COMPLEX_UNIT_PX, size);
    }

    public static void update(Chart chart, double leftValue, double rightValue) {
        if (!(chart instanceof BarLineChartBase)) return;
        BarLineChartBase bar = (BarLineChartBase) chart;
        ViewGroup parent = (ViewGroup) bar.getParent();
        if (parent == null) return;
        TextView left = parent.findViewWithTag(leftTag(bar));
        TextView right = parent.findViewWithTag(rightTag(bar));
        if (left == null || right == null) return;

        ValueFormatter vf = bar.getXAxis().getValueFormatter();

        ChartData data = bar.getData();
        float minIndex = data != null ? data.getXMin() : (float) leftValue;
        float maxIndex = data != null ? data.getXMax() : (float) rightValue;

        int leftIndex = (int) Math.ceil(leftValue);
        int rightIndex = (int) Math.floor(rightValue);

        if (leftIndex < minIndex) leftIndex = (int) minIndex;
        if (leftIndex > maxIndex) leftIndex = (int) maxIndex;
        if (rightIndex < minIndex) rightIndex = (int) minIndex;
        if (rightIndex > maxIndex) rightIndex = (int) maxIndex;

        left.setVisibility(View.VISIBLE);
        right.setVisibility(View.VISIBLE);

        left.setText(vf.getFormattedValue(leftIndex));
        if (rightIndex <= leftIndex) {
            right.setVisibility(View.GONE);
        } else {
            right.setText(vf.getFormattedValue(rightIndex));
        }

        reposition(bar);
    }

    public static void saveBaseOffsets(BarLineChartBase chart, float left, float top, float right, float bottom) {
        baseOffsets.put(chart, new float[]{left, top, right, bottom});
    }

    private static float[] base(BarLineChartBase chart) {
        float[] b = baseOffsets.get(chart);
        if (b == null) {
            b = new float[]{0f, 0f, 0f, 0f};
        }
        return b;
    }

    private static boolean isEnabled(BarLineChartBase chart) {
        Boolean e = enabledMap.get(chart);
        return e != null && e;
    }

    private static int overlayHeight(BarLineChartBase chart) {
        ViewGroup parent = (ViewGroup) chart.getParent();
        if (parent == null) return 0;
        TextView left = parent.findViewWithTag(leftTag(chart));
        if (left == null) return 0;
        int widthSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
        int heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED);
        left.measure(widthSpec, heightSpec);
        return left.getMeasuredHeight();
    }

    public static void applyPadding(BarLineChartBase chart) {
        float[] b = base(chart);
        float bottom = b[3];
        if (isEnabled(chart)) {
            bottom = (float) overlayHeight(chart) / 2f;
        }
        chart.setExtraOffsets(b[0], b[1], b[2], bottom);
    }
}
