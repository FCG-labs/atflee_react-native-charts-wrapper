package com.github.wuxudong.rncharts.charts.helpers;

import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.formatter.ValueFormatter;

/** Helper for fixed edge labels overlayed on the chart. */
public class EdgeLabelHelper {
    private static String leftTag(Chart chart) {
        return "edgeLabelLeft-" + chart.getId();
    }
    private static String rightTag(Chart chart) {
        return "edgeLabelRight-" + chart.getId();
    }

    public static void setEnabled(BarLineChartBase chart, boolean enabled) {
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

        if (!enabled) {
            if (left != null) parent.removeView(left);
            if (right != null) parent.removeView(right);
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

        style(chart);
        reposition(chart);
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

        left.layout(chartLeft, chartBottom - leftH, chartLeft + leftW, chartBottom);
        right.layout(chartRight - rightW, chartBottom - rightH, chartRight, chartBottom);

        left.bringToFront();
        right.bringToFront();
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
        left.setText(vf.getFormattedValue((float) leftValue));
        right.setText(vf.getFormattedValue((float) rightValue));

        reposition(bar);
    }
}
