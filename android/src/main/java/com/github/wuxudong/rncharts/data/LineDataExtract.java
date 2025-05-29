package com.github.wuxudong.rncharts.data;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;
import com.github.mikephil.charting.interfaces.datasets.IDataSet;
import com.github.wuxudong.rncharts.charts.ConfigurableMinimumLinePositionFillFormatter;
import com.github.wuxudong.rncharts.utils.BridgeUtils;
import com.github.wuxudong.rncharts.utils.ChartDataSetConfigUtils;
import com.github.wuxudong.rncharts.utils.ConversionUtil;
import com.github.wuxudong.rncharts.utils.DrawableUtils;

import java.lang.Exception;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;


/**
 * Created by xudong on 02/03/2017.
 */
public class LineDataExtract extends DataExtract<LineData, Entry> {
    @Override
    LineData createData() {
        return new LineData();
    }


    @Override
    IDataSet<Entry> createDataSet(ArrayList<Entry> entries, String label) {
        return new LineDataSet(entries, label);
    }

    @Override
    void dataSetConfig(Chart chart, IDataSet<Entry> dataSet, ReadableMap config) {
        LineDataSet lineDataSet = (LineDataSet) dataSet;

        ChartDataSetConfigUtils.commonConfig(chart, lineDataSet, config);
        ChartDataSetConfigUtils.commonBarLineScatterCandleBubbleConfig(lineDataSet, config);
        ChartDataSetConfigUtils.commonLineScatterCandleRadarConfig(lineDataSet, config);
        ChartDataSetConfigUtils.commonLineRadarConfig(lineDataSet, config);

        // LineDataSet only config
        if (BridgeUtils.validate(config, ReadableType.Number, "circleRadius")) {
            lineDataSet.setCircleRadius((float) config.getDouble("circleRadius"));
        }
        if (BridgeUtils.validate(config, ReadableType.Boolean, "drawCircles")) {
            lineDataSet.setDrawCircles(config.getBoolean("drawCircles"));
        }
        if (BridgeUtils.validate(config, ReadableType.String, "mode")) {
            lineDataSet.setMode(LineDataSet.Mode.valueOf(config.getString("mode")));
        }
        if (BridgeUtils.validate(config, ReadableType.Number, "drawCubicIntensity")) {
            lineDataSet.setCubicIntensity((float) config.getDouble("drawCubicIntensity"));
        }
        if (BridgeUtils.validate(config, ReadableType.Number, "circleColor")) {
            lineDataSet.setCircleColor(config.getInt("circleColor"));
        }
        if (BridgeUtils.validate(config, ReadableType.Array, "circleColors")) {
            lineDataSet.setCircleColors(BridgeUtils.convertToIntArray(config.getArray("circleColors")));
        }
        if (BridgeUtils.validate(config, ReadableType.Number, "circleHoleColor")) {
            lineDataSet.setCircleHoleColor(config.getInt("circleHoleColor"));
        }
        if (BridgeUtils.validate(config, ReadableType.Boolean, "drawCircleHole")) {
            lineDataSet.setDrawCircleHole(config.getBoolean("drawCircleHole"));
        }
        if (BridgeUtils.validate(config, ReadableType.Map, "dashedLine")) {
            ReadableMap dashedLine = config.getMap("dashedLine");
            float lineLength = 0;
            float spaceLength = 0;
            float phase = 0;

            if (BridgeUtils.validate(dashedLine, ReadableType.Number, "lineLength")) {
                lineLength = (float) dashedLine.getDouble("lineLength");
            }
            if (BridgeUtils.validate(dashedLine, ReadableType.Number, "spaceLength")) {
                spaceLength = (float) dashedLine.getDouble("spaceLength");
            }
            if (BridgeUtils.validate(dashedLine, ReadableType.Number, "phase")) {
                phase = (float) dashedLine.getDouble("phase");
            }

            lineDataSet.enableDashedLine(lineLength, spaceLength, phase);
        }
        if (BridgeUtils.validate(config, ReadableType.Map, "fillFormatter")) {
            ReadableMap fillFormatter = config.getMap("fillFormatter");
            float min = 0F;

            if (BridgeUtils.validate(fillFormatter, ReadableType.Number, "min")) {
                min = (float) fillFormatter.getDouble("min");
            }
            lineDataSet.setFillFormatter(new ConfigurableMinimumLinePositionFillFormatter(min));
        }
    }

    @Override
    Entry createEntry(ReadableArray values, int index) {
        float x = index;

        Entry entry;
        if (ReadableType.Map.equals(values.getType(index))) {
            ReadableMap map = values.getMap(index);
            if (map.hasKey("x")) {
                x = (float) map.getDouble("x");
            }

            if (map.hasKey("icon")) {
                ReadableMap icon = map.getMap("icon");
                ReadableMap bundle = icon.getMap("bundle");
                int width = icon.getInt("width");
                int height = icon.getInt("height");
                entry = new Entry(x, (float) map.getDouble("y"), DrawableUtils.drawableFromUrl(bundle.getString("uri"), width, height));

            } else {
                // y 원본을 먼저 가져옴
                double yRaw = map.getDouble("y");
                float  yVal;

                // decimalPlaces 키가 있으면 반올림, 없으면 그대로
                if (map.hasKey("decimalPlaces") && !map.isNull("decimalPlaces")) {
                    int dp = map.getInt("decimalPlaces");

                    // JS toFixed와 동일하게 HALF_UP 반올림
                    BigDecimal bd = BigDecimal.valueOf(yRaw)
                            .setScale(dp, RoundingMode.HALF_UP);

                    yVal = bd.floatValue();          // ★ 반올림 값
                } else {
                    yVal = (float) yRaw;             // ★ 원본 유지
                }

                // Entry 생성 (data 파라미터 필요하면 인자 생성자 사용)
                entry = new Entry(x, yVal, ConversionUtil.toMap(map));
            }
        } else if (ReadableType.Number.equals(values.getType(index))) {
            entry = new Entry(x, (float) values.getDouble(index));
        } else {
            throw new IllegalArgumentException("Unexpected entry type: " + values.getType(index));
        }

        return entry;
    }
}
