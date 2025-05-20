package com.github.wuxudong.rncharts.markers;

import android.content.Context;
import android.text.TextUtils;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import com.github.mikephil.charting.components.MarkerView;
import com.github.mikephil.charting.data.CandleEntry;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.mikephil.charting.utils.Utils;
import com.github.wuxudong.rncharts.R;

import java.util.Map;

public class RNAtfleeMarkerView extends MarkerView {

    private final TextView tvTitle;
    private final TextView tvContent;
    private final ImageView imageEmotion;

    public RNAtfleeMarkerView(Context context) {
        super(context, R.layout.atflee_marker);

        tvTitle = findViewById(R.id.x_value);
        tvContent = findViewById(R.id.y_value);
        imageEmotion = findViewById(R.id.image_emotion);
    }


    @Override
    public void refreshContent(Entry e, Highlight highlight) {
        String decimalPlaces = "0";
        String markerUnit = "";
        String markerString = "";
        String markerEmotion = "";

        // 날짜(타이틀)
        tvTitle.setText(getChartView().getXAxis().getValueFormatter().getFormattedValue(e.getX()));

        //
        if (e.getData() instanceof Map) {
            // 단위
            if (((Map) e.getData()).containsKey("markerUnit")) {
                Object marker = ((Map) e.getData()).get("markerUnit");
                markerUnit = marker.toString();
            }

            // marker 글자
            if (((Map) e.getData()).containsKey("marker")) {
                Object marker = ((Map) e.getData()).get("marker");
                markerString = marker.toString();
            }

            // decimal places
            if (((Map) e.getData()).containsKey("decimalPlaces")) {
                Object marker = ((Map) e.getData()).get("decimalPlaces");
                decimalPlaces = marker.toString();
            }

        }
        if (e instanceof CandleEntry) {
            CandleEntry ce = (CandleEntry) e;
            tvContent.setText(Utils.formatNumber(ce.getHigh(), 0, true));
        } else {
            if (markerString.isEmpty()) {
                tvContent.setText(String.format("%." + decimalPlaces + "f", e.getY()) + markerUnit);
            } else {
                tvContent.setText(markerString);
            }
        }

        // 감정 이모티콘
        if (e.getData() instanceof Map) {
            if (((Map) e.getData()).containsKey("markerEmotion")) {

                Object marker = ((Map) e.getData()).get("markerEmotion");
                markerEmotion = marker.toString();
            }
        }
        if (TextUtils.isEmpty(markerEmotion)) {
            imageEmotion.setVisibility(GONE);
        } else {
            imageEmotion.setVisibility(VISIBLE);
            if (markerEmotion.equalsIgnoreCase("1"))
                imageEmotion.setImageResource(R.drawable.emotion1);
            if (markerEmotion.equalsIgnoreCase("2"))
                imageEmotion.setImageResource(R.drawable.emotion2);
            if (markerEmotion.equalsIgnoreCase("3"))
                imageEmotion.setImageResource(R.drawable.emotion3);
            if (markerEmotion.equalsIgnoreCase("4"))
                imageEmotion.setImageResource(R.drawable.emotion4);
            if (markerEmotion.equalsIgnoreCase("5"))
                imageEmotion.setImageResource(R.drawable.emotion5);
        }

        super.refreshContent(e, highlight);
    }

    @Override
    public MPPointF getOffset() {
        if (imageEmotion.getVisibility() == View.VISIBLE) {
            return new MPPointF(-(getWidth() / 2), -getHeight());
        } else {
            return new MPPointF(-(getWidth() / 2), -getChartView().getHeight() + getHeight());
        }
    }

    @Override
    public MPPointF getOffsetForDrawingAtPoint(float posX, float posY) {
        float chartHeight = getChartView() != null ? getChartView().getHeight() : 0f;
        boolean showAbove = posY > chartHeight * 0.35f;

        float offsetX = -(getWidth() / 2f);
        float offsetY;

        if (showAbove) {
            offsetY = -getHeight();
        } else {
            offsetY = 0f;
            if (imageEmotion.getVisibility() == View.VISIBLE) {
                offsetY += imageEmotion.getHeight();
            }
        }

        return new MPPointF(offsetX, offsetY);
    }

    public TextView getTvTitle() {
        return tvTitle;
    }

    public TextView getTvContent() {
        return tvContent;
    }

}
