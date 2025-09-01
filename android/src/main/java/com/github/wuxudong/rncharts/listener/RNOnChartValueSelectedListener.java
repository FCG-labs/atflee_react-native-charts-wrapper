package com.github.wuxudong.rncharts.listener;

import com.facebook.react.bridge.ReactContext;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.listener.OnChartValueSelectedListener;
import com.github.wuxudong.rncharts.utils.EntryToWritableMapUtils;
import com.github.wuxudong.rncharts.markers.RNAtfleeMarkerView;

import java.lang.ref.WeakReference;
import java.util.WeakHashMap;

/**
 * Created by xudong on 07/03/2017.
 */
public class RNOnChartValueSelectedListener implements OnChartValueSelectedListener {

    private WeakReference<Chart> mWeakChart;
    private static final WeakHashMap<Chart, Boolean> SUPPRESS_NEXT_CLEAR = new WeakHashMap<>();

    /**
     * When called, the next onNothingSelected for the given chart will not emit
     * a topSelect(null) event. Useful to avoid duplicate chart events after
     * marker-driven clears.
     */
    public static void suppressNextClear(Chart chart) {
        if (chart != null) {
            SUPPRESS_NEXT_CLEAR.put(chart, Boolean.TRUE);
        }
    }

    public RNOnChartValueSelectedListener(Chart chart) {
        mWeakChart = new WeakReference<>(chart);
    }

    @Override
    public void onValueSelected(Entry entry, Highlight h) {

        if (mWeakChart != null) {
            Chart chart = mWeakChart.get();
            try {
                android.util.Log.d("AtfleeMarkerDebug", "topSelect: entry(x,y)=(" + entry.getX() + "," + entry.getY() + ")"
                        + ", datasetIndex=" + (h != null ? h.getDataSetIndex() : -1)
                        + ", xPx=" + (h != null ? h.getXPx() : Float.NaN)
                        + ", yPx=" + (h != null ? h.getYPx() : Float.NaN));
            } catch (Throwable ignore) {}
            ReactContext reactContext = (ReactContext) chart.getContext();
            reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                    chart.getId(),
                    "topSelect",
                    EntryToWritableMapUtils.convertEntryToWritableMap(entry));
        }
    }

    @Override
    public void onNothingSelected() {
        if (mWeakChart != null) {
            Chart chart = mWeakChart.get();

            // Clean up any stale overlay from custom marker
            if (chart != null && chart.getMarker() instanceof RNAtfleeMarkerView) {
                try {
                    ((RNAtfleeMarkerView) chart.getMarker()).detachOverlayIfPresent();
                } catch (Throwable t) {
                    // ignore
                }
            }

            // Suppress emission if this clear originates from a marker click
            if (SUPPRESS_NEXT_CLEAR.remove(chart) != null) {
                try { android.util.Log.d("AtfleeMarkerDebug", "onNothingSelected: suppressed by marker click"); } catch (Throwable ignore) {}
                return;
            }

            ReactContext reactContext = (ReactContext) chart.getContext();
            try { android.util.Log.d("AtfleeMarkerDebug", "onNothingSelected: emitted topSelect(null)"); } catch (Throwable ignore) {}
            reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                    chart.getId(),
                    "topSelect",
                    null);
        }

    }

}
