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
    private static final float PADDING_DP_RIGHT = 32f;
    private static java.util.WeakHashMap<BarLineChartBase, Boolean> enabledMap = new java.util.WeakHashMap<>();
    private static java.util.WeakHashMap<BarLineChartBase, Boolean> explicitMap = new java.util.WeakHashMap<>();
    // orientation override: null means auto-detect
    private static java.util.WeakHashMap<BarLineChartBase, Boolean> landscapeOverrideMap = new java.util.WeakHashMap<>();
    // remembers user-specified drawLabels flag for xAxis
    private static java.util.WeakHashMap<BarLineChartBase, Boolean> userDrawLabelsMap = new java.util.WeakHashMap<>();
    private static java.util.WeakHashMap<BarLineChartBase, float[]> baseOffsets = new java.util.WeakHashMap<>();
    private static java.util.WeakHashMap<BarLineChartBase, float[]> edgePixels = new java.util.WeakHashMap<>();
    private static java.util.WeakHashMap<BarLineChartBase, Float> minScaleXMap = new java.util.WeakHashMap<>();
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

        int overlayH = overlayHeight(chart);
        float[] pixels = edgePixels.get(chart);
        int leftX = chartLeft + padLeft;
        int rightX = chartRight - rightW - padRight;
        if (pixels != null && pixels.length >= 2) {
            leftX = Math.round(chartLeft + pixels[0] - leftW / 2f);
            rightX = Math.round(chartLeft + pixels[1] - rightW / 2f);
        }
        left.layout(leftX, chartBottom - overlayH, leftX + leftW, chartBottom);
        right.layout(rightX, chartBottom - overlayH, rightX + rightW, chartBottom);

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

        boolean atMinScale = isAtMinScaleX(bar);
        int leftIndex = (int) Math.ceil(atMinScale ? minIndex : leftValue);
        int rightIndex = (int) Math.ceil(atMinScale ? maxIndex : rightValue);

        if (leftIndex < minIndex) leftIndex = (int) minIndex;
        if (leftIndex > maxIndex) leftIndex = (int) maxIndex;
        if (rightIndex < minIndex) rightIndex = (int) minIndex;
        if (rightIndex > maxIndex) rightIndex = (int) maxIndex;

        left.setVisibility(View.VISIBLE);
        right.setVisibility(View.VISIBLE);
        edgePixels.put(bar, new float[]{
                (float) bar.getTransformer(com.github.mikephil.charting.components.YAxis.AxisDependency.LEFT)
                        .getPixelForValues(leftIndex, 0).x,
                (float) bar.getTransformer(com.github.mikephil.charting.components.YAxis.AxisDependency.LEFT)
                        .getPixelForValues(rightIndex, 0).x
        });

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

    public static void setMinScaleX(BarLineChartBase chart, java.lang.Float minScaleX) {
        if (minScaleX == null) {
            minScaleXMap.remove(chart);
        } else {
            minScaleXMap.put(chart, minScaleX);
        }
    }

    public static boolean isAtMinScaleX(BarLineChartBase chart) {
        Float minScaleX = minScaleXMap.get(chart);
        ChartData data = chart.getData();
        if (data != null) {
            float left = chart.getLowestVisibleX();
            float right = chart.getHighestVisibleX();
            if (left <= data.getXMin() + 0.51f && right >= data.getXMax() - 0.51f) return true;
        }
        if (minScaleX == null || minScaleX <= 0f) return false;
        return chart.getScaleX() <= minScaleX + 0.05f;
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
            bottom = b[3] + (float) overlayHeight(chart) / 2f;
        }
        chart.setExtraOffsets(b[0], b[1], b[2], bottom);
    }

    /** Saves explicit edgeLabelEnabled flag coming from JS. */
    public static void setExplicitFlag(BarLineChartBase chart, Boolean explicit) {
        if (explicit == null) {
            explicitMap.remove(chart);
        } else {
            explicitMap.put(chart, explicit);
        }
    }

    /** Returns explicit flag if provided; otherwise null (auto). */
    public static java.lang.Boolean getExplicitFlag(BarLineChartBase chart) {
        return explicitMap.get(chart);
    }

    /** Stores optional landscape override flag from JS. */
    public static void setLandscapeOverride(BarLineChartBase chart, java.lang.Boolean landscape) {
        if (landscape == null) {
            landscapeOverrideMap.remove(chart);
        } else {
            landscapeOverrideMap.put(chart, landscape);
        }
    }

    /** Returns landscape override if provided; otherwise null. */
    public static java.lang.Boolean getLandscapeOverride(BarLineChartBase chart) {
        return landscapeOverrideMap.get(chart);
    }

    /** Remembers user-specified drawLabels flag for xAxis. */
    public static void setUserDrawLabels(BarLineChartBase chart, java.lang.Boolean enabled) {
        if (enabled == null) {
            userDrawLabelsMap.remove(chart);
        } else {
            userDrawLabelsMap.put(chart, enabled);
        }
    }

    /** Returns user-specified drawLabels flag for xAxis, or null if not provided. */
    public static java.lang.Boolean getUserDrawLabels(BarLineChartBase chart) {
        return userDrawLabelsMap.get(chart);
    }
}
