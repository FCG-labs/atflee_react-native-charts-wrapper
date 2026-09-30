# Documentation

## For complete properties list, please check files under lib/*

## Description (prop for all charts)

| Prop         | Type     | Default | Note |
| ------------ | -------- | ------- | ---- |
| `text`       | `string` |         |      |
| `textColor`  | `number` |         |      |
| `textSize`   | `number` |         |      |
| `positionX`  | `number` |         |      |
| `positionY`  | `number` |         |      |

## Legend (prop for all charts)

| Prop                      | Type                                                          | Default | Note |
| ------------------------- | ------------------------------------------------------------- | ------- | ---- |
| `enabled`                 | `bool`                                                        |         |      |
| `text`                    | `string`                                                      |         |      |
| `textColor`               | `number`                                                      |         |      |
| `textSize`                | `number`                                                      |         |      |
| `fontFamily`              | `string`                                                      |         |      |
| `fontStyle`               | `number`                                                      |         |      |
| `wordWrapEnabled`         | `bool`                                                        |         |      |
| `maxSizePercent`          | `number`                                                      |         |      |
| `horizontalAlignment`     | one of `'LEFT', 'CENTER', 'RIGHT'`                            |         |      |
| `verticalAlignment`       | one of `'TOP', 'CENTER', 'BOTTOM'`                            |         |      |
| `orientation`             | one of `'HORIZONTAL', 'VERTICAL'`                             |         |      |
| `drawInside`              | `bool`                                                        |         |      |
| `direction`               | one of `LEFT_TO_RIGHT', 'RIGHT_TO_LEFT`                       |         |      |
| `form`                    | `string`                                                      |         |      |
| `formSize`                | `number`                                                      |         |      |
| `xEntrySpace`             | `bool`                                                        |         |      |
| `yEntrySpace`             | `number`                                                      |         |      |
| `formToTextSpace`         | `number`                                                      |         |      |
| `custom`                  | `{`<br />`colors: [number],`<br />`labels: [string]`<br />`}` |         |      |

## Common Props for xAxis and yAxis

| Prop                       | Type                                                                                     | Default | Note                                                                                                                        |
| -------------------------- | ---------------------------------------------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------- |
| `enabled`                  | `bool`                                                                                   |         |                                                                                                                             |
| `drawLabels`               | `bool`                                                                                   |         |                                                                                                                             |
| `drawAxisLine`             | `bool`                                                                                   |         |                                                                                                                             |
| `drawGridLines`            | `bool`                                                                                   |         |                                                                                                                             |
| `textColor`                | `number`                                                                                 |         |                                                                                                                             |
| `textSize`                 | `number`                                                                                 |         |                                                                                                                             |
| `fontFamily`               | `string`                                                                                 |         |                                                                                                                             |
| `fontStyle`                | `number`                                                                                 |         |                                                                                                                             |
| `gridColor`                | `bool`                                                                                   |         |                                                                                                                             |
| `gridLineWidth`            | `bool`                                                                                   |         |                                                                                                                             |
| `axisLineColor`            | `bool`                                                                                   |         |                                                                                                                             |
| `axisLineWidth`            | `bool`                                                                                   |         |                                                                                                                             |
| `gridDashedLine`           | `{`<br />`lineLength: number,`<br />`spaceLength: number,`<br />`phase: number`<br />`}` |         |                                                                                                                             |
| `limitLines`               | array : `[{ limit: number, label: string, lineColor: number, lineWidth: number, valueTextColor: number, valueFont: number, fontFamily: string, fontStyle: string, fontWeight: string, labelPosition: string, lineDashPhase: number, lineDashLengths: [number] }]`                                                                                 |         |                                                                                                                             |
| `drawLimitLinesBehindData` | `bool`                                                                                   |         |                                                                                                                             |
| `axisMaximum`              | `number`                                                                                 |         |                                                                                                                             |
| `axisMinimum`              | `number`                                                                                 |         |                                                                                                                             |
| `granularity`              | `number`                                                                                 |         |                                                                                                                             |
| `granularityEnabled`       | `bool`                                                                                   |         |                                                                                                                             |
| `labelCount`               | `number`                                                                                 |         |                                                                                                                             |
| `labelCountForce`          | `bool`                                                                                   |         |                                                                                                                             |
| `centerAxisLabels`         | `bool`                                                                                   |         | Centers the axis labels instead of drawing them at their original position. This is useful especially for grouped BarChart. |
| `valueFormatter`           | one of `'largeValue', 'percent', 'date', string, [string]`                               |         |                                                                                                                             |
| `valueFormatterPattern`    | `string`                                                                                 |         |
| `yOffset`                  | `number`                                                                                 |    0    | adjust vertical label position

## xAxis

#### Common props plus props below.

| Prop                     | Type     | Default | Note |
| ------------------------ | -------- | ------- | ---- |
| `labelRotationAngle`     | `number` |         |      |
| `avoidFirstLastClipping` | `bool`   |         |      |
| `edgeLabelEnabled`       | `bool`   |         | Hide normal x-axis labels and draw two padded labels at the visible range edges. The chart adds bottom padding equal to half the label height so they never overlap the data. The labels include top padding and update automatically as you scroll or zoom |
| `position`               | `string` |         | Should be in upper case. you will get an error in android if the position is in lower case      |
| `valueFormatterPattern`  | `string` |         |      |

## yAxis

#### Common props plus props below.

| Prop          | Type                                                                                  | Default | Note |
| ------------- | ------------------------------------------------------------------------------------- | ------- | ---- |
| `inverted`    | `number`                                                                              |         |      |
| `left`			  | `config`                                                                              |         | Applies config to left line      |
| `right`		    | `config`                                                                              |         | Applies config to right line     |
| `spaceTop`    | `bool`                                                                                |         |      |
| `spaceBottom` | `number`                                                                              |         |      |
| `position`    | `number`                                                                              |         |      |
| `maxWidth`    | `bool`                                                                                |         |      |
| `minWidth`    | `string`                                                                              |         |      |
| `zeroLine`    | `{`<br />`enabled: bool,`<br />`lineWidth: number,`<br />`lineColor: number`<br />`}` |         |      |

## Chart Base (All charts have these props)

#### Chart Base inherits props from react-native 'View' in addition to the props below.

| Prop                           | Type                                                                                                                                            | Default | Note                                                                                                                                                                                                                                                        |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `animation`                    | `{`<br />`durationX: number,`<br />`durationY: number,`<br />`easingX: string,`<br />`easingY: string`<br />`}`                                 |         | Durations are in milliseconds.                                                                                                                                                                                                                              |
| `chartBackgroundColor`         | `number`                                                                                                                                        |         |                                                                                                                                                                                                                                                             |
| `logEnabled`                   | `bool`                                                                                                                                          |         |                                                                                                                                                                                                                                                             |
| `noDataText`                   | `string`                                                                                                                                        |         |                                                                                                                                                                                                                                                             |
| `noDataTextColor`              | `number`                                                                                                                                        |         |                                                                                                                                                                                                                                                             |
| `touchEnabled`                 | `bool`                                                                                                                                          |         |                                                                                                                                                                                                                                                             |
| `dragDecelerationEnabled`      | `bool`                                                                                                                                          |         |                                                                                                                                                                                                                                                             |
| `dragDecelerationFrictionCoef` | `function`                                                                                                                                      |         |                                                                                                                                                                                                                                                             |
| `chartDescription`             | `Description`                                                                                                                                   |         |                                                                                                                                                                                                                                                             |
| `legend`                       | `Legend`                                                                                                                                        |         |                                                                                                                                                                                                                                                             |
| `xAxis`                        | `XAksis`                                                                                                                                        |         |                                                                                                                                                                                                                                                             |
| `marker`                       | `{`<br />`enabled: bool,`<br />`digits: number,`<br />`markerColor: number,`<br />`textColor: number,`<br />`textSize: number,<br />textWeight: string,<br />fixedOnTop: bool`<br />`}`         |         |                                                                                                                                                                                                                                                             |
| `highlights`                   | Array of <br/>`{`<br />`x: number,`<br />`dataSetIndex: number,`<br />`dataIndex: number,`<br />`y: number,`<br />`stackIndex: number`<br />`}` |         | `x` is required and represents the index of the x values.<br /> `dataSetIndex` is used in stacked bar chart.<br />`dataIndex` is necessary in combined chart when default highlight is set. The default sequence is line, bar, scatter, candle, bubble. |

## BarLineChartBase

#### _Chart Base props plus props listed below_.

| Prop                     | Type                                                                                                                                                            | Default | Note |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ---- |
| `drawGridBackground`     | `bool`                                                                                                                                                          |         |      |
| `gridBackgroundColor`    | `number`                                                                                                                                                        |         |      |
| `drawBorders`            | `bool`                                                                                                                                                          |         |      |
| `borderColor`            | `number`                                                                                                                                                        |         |      |
| `borderWidth`            | `number`                                                                                                                                                        |         |      |
| `minOffset`              | `number`                                                                                                                                                        |         |      |
| `maxVisibleValueCount`   | `number`                                                                                                                                                        |         |      |
| `visibleRange`           | `{`<br />`x: { min: number, max: number },`<br />`y: {`<br />`left: { min: number, max: number },`<br />`right: { min: number, max: number }`<br />`}`<br />`}` |         |      |
| `autoScaleMinMaxEnabled` | `bool`                                                                                                                                                          |         |      |
| `keepPositionOnRotation` | `bool`                                                                                                                                                          |         |      |
| `scaleEnabled`           | `bool`                                                                                                                                                          |         |      |
| `scaleXEnabled`          | `bool`                                                                                                                                                          |         |      |
| `scaleYEnabled`          | `bool`                                                                                                                                                          |         |      |
| `dragEnabled`            | `bool`                                                                                                                                                          |         |      |
| `pinchZoom`              | `bool`                                                                                                                                                          |         |      |
| `doubleTapToZoomEnabled` | `bool`                                                                                                                                                          |         |      |
| `yAksis`                 | `{ left: YAksis, right: YAksis }`                                                                                                                               |         |      |
| `zoom`                   | `{`<br />`scaleX: number,`<br />`scaleY: number,`<br />`xValue: number,`<br />`yValue: number,`<br />`axisDependency: 'LEFT' or 'RIGHT'`<br />`}`               |         |      |
| `viewPortOffsets`        | `{`<br />`left: number,`<br />`top: number,`<br />`right: number,`<br />`bottom: number,`<br />`}`                                                              |         |      |

## BarChart

#### _ChartBase props plus props listed below_.

| Prop                | Type                | Default | Note |
| ------------------- | ------------------- | ------- | ---- |
| `drawValueAboveBar` | `bool`              |         |      |
| `drawBarShadow`     | `bool`              |         |      |
| `barRadius`         | `number`            |         | Pixel radius of bar corners. When greater than `0`, a rounded bar renderer is used. Android only unless implemented for iOS. |
| `data`              | `DataTypes.barData` |         |      |

## BubbleChart

#### _BarLineChartBase props plus props listed below_.

| Prop   | Type                   | Default | Note |
| ------ | ---------------------- | ------- | ---- |
| `data` | `DataTypes.bubbleData` |         |      |

## CandleStickChart

#### _BarLineChartBase props plus props listed below_.

| Prop   | Type                   | Default | Note |
| ------ | ---------------------- | ------- | ---- |
| `data` | `DataTypes.candleData` |         |      |

## CombinedChart

#### _BarLineChartBase props plus props listed below_.

| Prop        | Type                                                 | Default | Note |
| ------      | ---------------------------------------------------- | ------- | ---- |
| `data`      | `DataTypes.combinedData`                             |         |      |
| `drawOrder` | `array with one of: ['SCATTER', 'BAR', 'LINE']`      |         |      |
| `drawValueAboveBar` | `bool`              |         |      |
| `highlightFullBarEnabled` | `bool`         |         |      |
| `drawBarShadow`     | `bool`              |         |      |
| `barRadius`         | `number`            |         | Pixel radius of bar corners. When greater than `0`, a rounded bar renderer is used. Android only unless implemented for iOS. |

## HorizontalBarChart

#### _BarLineChartBase props plus props listed below_.

| Prop                | Type                | Default | Note |
| ------------------- | ------------------- | ------- | ---- |
| `drawValueAboveBar` | `bool`              |         |      |
| `drawBarShadow`     | `bool`              |         |      |
| `barRadius`         | `number`            |         | Pixel radius of bar corners. When greater than `0`, a rounded bar renderer is used. Android only unless implemented for iOS. |
| `data`              | `DataTypes.barData` |         |      |

## LineChart

#### _BarLineChartBase props plus props listed below_.

| Prop   | Type                 | Default | Note |
| ------ | -------------------- | ------- | ---- |
| `data` | `DataTypes.lineData` |         |      |

### Line dataset `config.densityStyle` (FCG fork)

보이는 점 개수(n)로 점 반지름·선 굵기·중간 점 표시를 **네이티브 렌더러가 매 프레임** 정한다. JS 는 기준값만 한 번 넘긴다 — 줌·끌기·탭 전환 때 JS 가 보이는 구간을 추측해 조형을 다시 보낼 필요가 없다. **CombinedChart 의 선 데이터셋**(양 플랫폼)에 쓴다. LineChart 는 Android 만 — iOS LineChart 는 기본 렌더러라 키가 무시된다. 키가 없으면 지금 동작 그대로다(`circleRadius`·`lineWidth`·`drawCircles` 가 그대로 쓰인다). 크기 단위는 iOS pt / Android dp. 반지름은 Android 가 1 미만을 받지 않아 1 에서 멈춘다. 레이아웃 전 첫 프레임(내용 영역이 없을 때)에는 config 의 `circleRadius`·`lineWidth` 가 쓰이므로 기준값과 같게 넣어 둔다.

| Key | Default | Note |
| --- | ------- | ---- |
| `referenceCount` | `7` | 이 개수(n0)가 보일 때의 반지름·굵기가 기준값이자 상한 |
| `circleRadius` | `4` | n0 에서의 점 반지름 R0. r(n) = min(R0, R0·√((n0−1)/(n−1))) |
| `lineWidth` | `3` | n0 에서의 선 굵기 W0. w(n) = min(W0, max(Wmin, W0·(√((n0−1)/(n−1)))^e)) |
| `minLineWidth` | `1.4` | Wmin |
| `lineWidthExponent` | `0.6` | e — 선은 점보다 덜 줄인다 |
| `endsOnlyAbove` | `30` | 보이는 점이 이 수를 넘으면 중간 점을 숨기고 **보이는 구간의 양 끝 점만** 그린다 |
| `endsOnlyReleaseAbove` | `28` | 숨긴 뒤에는 이 수를 넘는 동안 계속 숨긴다(경계 떨림 방지) |
| `endCircleRadiusRatio` | `0.85` | 양 끝 점 반지름 = max(minEndCircleRadius, R0·ratio·w(n)/W0) |
| `minEndCircleRadius` | `2` | 양 끝 점 반지름 하한 |

`drawCircles: false` 면 점은 그리지 않는다(선 굵기만 따른다). 걸쇠 상태는 데이터가 새로 심길 때마다 처음부터 판정한다 — 보이는 구간이 바뀔 때 data 를 다시 보내지 않는다(조형은 네이티브가 정한다). 점이 작아지므로 `drawCircleHole: false` 와 함께 쓰는 것을 권한다(켜 두면 구멍이 점보다 작을 때만 그린다).

Android CombinedChart 는 크기가 정해지기 전에 걸린 `zoom`(뷰포트 작업)을 첫 그리기 전에 적용한다 — 새로 만든 차트의 첫 프레임이 전 구간으로 그려졌다가 줌되는 일이 없다(iOS 는 원래 그렇다). `xAxis.edgeValueFormatter` 로 가장자리 날짜를 자동으로 켜고 끄는 차트는 그 첫 줌에 맞춰 x축 라벨 모드·값 라벨도 첫 그리기 전에 다시 정한다.

## ScatterChart

#### _BarLineChartBase props plus props listed below_.

| Prop   | Type                    | Default | Note |
| ------ | ----------------------- | ------- | ---- |
| `data` | `DataTypes.scatterData` |         |      |

## PieRadarChartBase

#### _ChartBase props plus props listed below_.

| Prop              | Type     | Default | Note |
| ----------------- | -------- | ------- | ---- |
| `minOffset`       | `number` |         |      |
| `rotationEnabled` | `bool`   |         |      |
| `rotationAngle`   | `number` |         |      |

## PieChart

#### _PieRadarChartBase props plus props listed below_.

| Prop                      | Type                                                                                                   | Default | Note |
| ------------------------- | ------------------------------------------------------------------------------------------------------ | ------- | ---- |
| `extraOffsets`            | `{`<br />`left: number,`<br />`top: number,`<br />`right: number,`<br />`bottom: number,`<br />`}`     |         |      |
| `drawEntryLabels`         | `bool`                                                                                                 |         |      |
| `usePercentValues`        | `bool`                                                                                                 |         |      |
| `centerText`              | `string`                                                                                               |         |      |
| `styledCenterText`        | `{`<br />`text: string,`<br />`color: number,`<br />`fontFamily: string,`<br />`size: number`<br />`}` |         |      |
| `centerTextRadiusPercent` | `number`                                                                                               |         |      |
| `holeRadius`              | `number`                                                                                               |         |      |
| `holeColor`               | `number`                                                                                               |         |      |
| `transparentCircleRadius` | `number`                                                                                               |         |      |
| `transparentCircleColor`  | `number`                                                                                               |         |      |
| `entryLabelColor`         | `number`                                                                                               |         |      |
| `entryLabelTextSize`      | `number`                                                                                               |         |      |
| `entryLabelFontFamily`    | `string`                                                                                               |         |      |
| `maxAngle`                | `number`                                                                                               |         |      |
| `data`                    | `DataTypes.pieData`                                                                                    |         |      |

## RadarChart

#### _PieRadarChartBase props plus props listed below_.

| Prop               | Type                  | Default | Note |
| ------------------ | --------------------- | ------- | ---- |
| `yAxis`            | `YAxis`               |         |      |
| `drawWeb`          | `bool`                |         |      |
| `skipWebLineCount` | `number`              |         |      |
| `data`             | `DataTypes.radarData` |         |      |

# ConfigTypes

```
type common {
  colors: [number],
  highlightEnabled: bool,
  drawValues: bool,
  valueTextSize: number,
  valueTextColor: number,
  visible: bool,
  valueFormatter: string or 'largeValue' or 'percent' or 'date' or 'labelByXValue',
  valueFormatterPattern: string,
  valueFormatterLabels: {
    x: number, // required
    label: string // required
  },
  axisDependency: string,
}
```

```
type barLineScatterCandleBubble { highlightColor: number }
```

```
type lineScatterCandleRadar {
  drawVerticalHighlightIndicator: bool,
  drawHorizontalHighlightIndicator: bool,
  highlightLineWidth: number
}
```

```
type lineRadar 	{
  fillGradient: {
    colors: [number],
    // iOS
    positions: [numbers],
    angle: number,
    //Android
    orientation: 'TOP_BOTTOM' | 'TR_BL' | 'RIGHT_LEFT' | 'BR_TL' | 'BOTTOM_TOP' | 'BL_TR' | 'LEFT_RIGHT' | 'TL_BR',
  },
  fillColor: number,
  fillAlpha: number,
  drawFilled: function
}
```

# DataTypes

```
type lineData {
  dataSets: [
    {
      values: [
        number or
        {
          x: number,
          y: number,
          marker: string
        }
      ],
      label: string, // required
      config: {
        ...ConfigTypes.common,
        ...ConfigTypes.barLineScatterCandleBubble,
        ...ConfigTypes.lineScatterCandleRadar,
        ...ConfigTypes.lineRadar,
        circleRadius: number,
        drawCircles: bool,
        mode: bool,
        lineWidth: number, // min: 0, max: 10
        drawCubicIntensity: number,
        circleColor: number,
        circleColors: [number],
        circleHoleColor: number,
        drawCircleHole: bool,
        dashedLine: {
          lineLength: number, // required
          spaceLength: number, // required
          phase: number
        },
        fillFormatter: {
            min: number // required
        }
      }
    }
  ]
}
```

```
type barData {
  dataSets: [
    {
      values: [
        {
          x: number,
          y: number or [number],
          marker: string or [string]
        }
        or number or [number]
      ],
      label: string, // required
      config: {
        ...ConfigTypes.common,
        ...ConfigTypes.barLineScatterCandleBubble,
        barShadowColor: number,
        highlightAlpha: number,  // using android format (0-255), not ios format(0-1), the conversion is x/255
        stackLabels: [string]
      }
    }
  ],
  config: {
    barWidth: number,
    group: {
      fromX: number, // required
      groupSpace: number, // required
      barSpace: number // required
    }
  }
}
```

```
type bubbleData {
  dataSets: [
    {
      values: [
        {
          x: PropTypes.number,
          y: PropTypes.number, // required
          size: PropTypes.number, // required
          marker: PropTypes.string,
        }
      ],
      label: string, // required
      config: {
        ...ConfigTypes.common,
        ...ConfigTypes.barLineScatterCandleBubble
      }
    }
  ]
}
```

```
type candleData {
  dataSets: [
    {
      values: [
        {
          x: number,
          shadowH: number, // required
          shadowL: number, // required
          open: number, // required
          close: number, // required
          marker: string,
        }
      ],
      label: string, // required
      config: {
        ...ConfigTypes.common,
        ...ConfigTypes.barLineScatterCandleBubble,
        ...ConfigTypes.lineScatterCandleRadar,

        barSpace: number,
        shadowWidth: number,
        shadowColor: number,
        shadowColorSameAsCandle: bool,
        neutralColor: number,
        decreasingColor: number,
        decreasingPaintStyle: string,
        increasingColor: number,
        increasingPaintStyle: string
      }
    }
  ]
}
```

```
type pieData {
  dataSets: [
    {
      values: [
        {
          value: number, // required
          label: string
        }
        or number
      ],
      label: string, // required
      config: {
        ...ConfigTypes.common,

        sliceSpace: number,
        selectionShift: number,
        xValuePosition: string, // INSIDE_SLICE,OUTSIDE_SLICE
        yValuePosition: string // INSIDE_SLICE,OUTSIDE_SLICE
      }
    }
  ]
}
```

```
type radarData {
  dataSets: [
    {
      values: [
        {
          value: number // required
        }
        or number
      ],
      label: string, // required
      config: {
        ...ConfigTypes.common,
        ...ConfigTypes.lineScatterCandleRadar,
        ...ConfigTypes.lineRadar
      }
    }
  ],
  labels: [string]
}
```

```
type scatterData {
  dataSets: [
    {
      values: [
        {
          x: number,
          y: number, // required
          marker: string,
        }
        or number
      ],
      label: string, // required
      config: {
        ...ConfigTypes.common,
        ...ConfigTypes.barLineScatterCandleBubble,
        ...ConfigTypes.lineScatterCandleRadar,

        scatterShapeSize: number,
        scatterShape: 'SQUARE' or 'CIRCLE' or 'TRIANGLE' or 'CROSS' or 'X'
        scatterShapeHoleColor: number,
        scatterShapeHoleRadius: number
      }
    }
  ],
  labels: [string]
}
```

```
type combinedData {
  lineData: lineData,
  barData: barData,
  scatterData: scatterData,
  candleData: candleData,
  bubbleData: bubbleData
}
```

## Callbacks

```jsx
const handleChange = e => {
  if (e.nativeEvent.action === 'chartLoadComplete') {
    // chart has finished rendering or props were updated
  }
};
<LineChart onChange={handleChange} ... />
```

Payload fields: `scaleX`, `scaleY`, `centerX`, `centerY`, `left`, `right`, `top`, `bottom`.
