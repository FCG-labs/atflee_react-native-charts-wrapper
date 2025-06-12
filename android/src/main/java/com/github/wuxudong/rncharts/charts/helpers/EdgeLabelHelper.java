package com.github.wuxudong.rncharts.charts.helpers;

import android.util.TypedValue;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout;
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
        if (parent == null) return;

        TextView left = parent.findViewWithTag(leftTag(chart));
        TextView right = parent.findViewWithTag(rightTag(chart));

        if (!enabled) {
            if (left != null) parent.removeView(left);
            if (right != null) parent.removeView(right);
            return;
        }

        if (left == null) {
            left = new TextView(chart.getContext());
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.gravity = Gravity.START | Gravity.BOTTOM;
            parent.addView(left, lp);
            left.setTag(leftTag(chart));
        }
        if (right == null) {
            right = new TextView(chart.getContext());
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.gravity = Gravity.END | Gravity.BOTTOM;
            parent.addView(right, lp);
            right.setTag(rightTag(chart));
        }

        style(chart);
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
    }
}
