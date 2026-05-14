//
// Created by xudong wu on 26/02/2017.
// Copyright (c) wuxudong. All rights reserved.
//

import Foundation
import DGCharts
import SwiftyJSON


class RNBarLineChartViewBase: RNYAxisChartViewBase {
    fileprivate var barLineChart: BarLineChartViewBase {
        get {
            return chart as! BarLineChartViewBase
        }
    }

    var savedVisibleRange : NSDictionary?

    var savedZoom : NSDictionary?

    var zoomScaleX: CGFloat?

    var needsFullZoomOut = false

    var savedExtraOffsets: NSDictionary?

    var _onYaxisMinMaxChange : RCTBubblingEventBlock?
    var timer : Timer?

    override func setYAxis(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        if json["left"].exists() {
            let leftYAxis = barLineChart.leftAxis
            setCommonAxisConfig(leftYAxis, config: json["left"]);
            setYAxisConfig(leftYAxis, config: json["left"]);
        }


        if json["right"].exists() {
            let rightAxis = barLineChart.rightAxis
            setCommonAxisConfig(rightAxis, config: json["right"]);
            setYAxisConfig(rightAxis, config: json["right"]);
        }
    }

    func setOnYaxisMinMaxChange(_ callback: RCTBubblingEventBlock?) {
      self._onYaxisMinMaxChange = callback;
      self.timer?.invalidate();
      if callback == nil {
        return;
      }

      var lastMin: Double = 0;
      var lastMax: Double = 0;

      let axis = (self.chart as! BarLineChartViewBase).getAxis(.right);

      if #available(iOS 10.0, *) {
        // Interval for 16ms
        self.timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
          let minimum = axis.axisMinimum;
          let maximum = axis.axisMaximum;
          if lastMin != minimum || lastMax != maximum {
            guard let callback = self._onYaxisMinMaxChange else {
              return;
            }
            callback([
              "minY": minimum,
              "maxY": maximum,
            ]);
          }
          lastMin = minimum;
          lastMax = maximum;
        }
      } else {
        // Fallback on earlier versions
      }
    }

    func setMaxHighlightDistance(_  maxHighlightDistance: CGFloat) {
        barLineChart.maxHighlightDistance = maxHighlightDistance;
    }

    func setDrawGridBackground(_  enabled: Bool) {
        barLineChart.drawGridBackgroundEnabled = enabled;
    }


    func setGridBackgroundColor(_ color: Int) {
        barLineChart.gridBackgroundColor = RCTConvert.uiColor(color);
    }


    func setDrawBorders(_ enabled: Bool) {
        barLineChart.drawBordersEnabled = enabled;
    }

    func setBorderColor(_ color: Int) {

        barLineChart.borderColor = RCTConvert.uiColor(color);
    }

    func setBorderWidth(_ width: CGFloat) {
        barLineChart.borderLineWidth = width;
    }


    func setMaxVisibleValueCount(_ count: NSInteger) {
        barLineChart.maxVisibleCount = count;
    }

    func setVisibleRange(_ config: NSDictionary) {
        NSLog("[ChartZoom] setVisibleRange called: config=%@ scaleX=%f minScaleX=%f", config, barLineChart.scaleX, barLineChart.viewPortHandler.minScaleX)
        if config == NSNull() || config.count == 0 {
            // visibleRange 해제 → fitScreen만 호출
            savedVisibleRange = nil
            // setMinimumScaleX(1.0) 제거 - scaleX < 1.0이 필요한 경우 줌아웃 차단
            barLineChart.fitScreen()
            NSLog("[ChartZoom] setVisibleRange NULL: fitScreen done. scaleX=%f minScaleX=%f maxScaleX=%f", barLineChart.scaleX, barLineChart.viewPortHandler.minScaleX, barLineChart.viewPortHandler.maxScaleX)
            return
        }
        // delay visibleRange handling until chart data is set
        savedVisibleRange = config
        // execute on next run-loop to ensure layout is finished
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.barLineChart.data != nil {
                self.updateVisibleRange(config)
            }
        }
    }

    func updateVisibleRange(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        let x = json["x"]

        let hasMax = x["max"].double != nil
        if hasMax {
            barLineChart.setVisibleXRangeMaximum(x["max"].doubleValue)
        }

        // max가 있으면 min 설정 건너뜀 → autoZoomPending에서 fitScreen 후 설정
        // max가 없으면 기존대로 min 설정
        if !hasMax && x["min"].double != nil {
            barLineChart.setVisibleXRangeMinimum(x["min"].doubleValue)
        }

        let y = json["y"]
        if y["left"]["min"].double != nil {
            barLineChart.setVisibleYRangeMinimum(y["left"]["min"].doubleValue, axis: YAxis.AxisDependency.left)
        }
        if y["left"]["max"].double != nil {
            barLineChart.setVisibleYRangeMaximum(y["left"]["max"].doubleValue, axis: YAxis.AxisDependency.left)
        }

        if y["right"]["min"].double != nil {
            barLineChart.setVisibleYRangeMinimum(y["right"]["min"].doubleValue, axis: YAxis.AxisDependency.right)
        }
        if y["right"]["max"].double != nil {
            barLineChart.setVisibleYRangeMaximum(y["right"]["max"].doubleValue, axis: YAxis.AxisDependency.right)
        }

        if let target = zoomScaleX, target > 0, barLineChart.scaleX != target {
            let relative = target / barLineChart.scaleX
            let centerX = barLineChart.data?.xMax ?? 0
            let axis = barLineChart.getAxis(.left).isEnabled ? YAxis.AxisDependency.left : YAxis.AxisDependency.right
            barLineChart.zoom(scaleX: relative, scaleY: 1.0, xValue: centerX, yValue: 0.0, axis: axis)
        } else if let saved = savedVisibleRange,
                  let xMap = saved["x"] as? NSDictionary {
            let rawDataXMin = barLineChart.data?.xMin ?? barLineChart.chartXMin
            let rawDataXMax = barLineChart.data?.xMax ?? barLineChart.chartXMax
            let effectiveXMin = min(rawDataXMin, barLineChart.chartXMin)
            let effectiveXMax = max(rawDataXMax, barLineChart.chartXMax)
            let totalRange = Double(effectiveXMax - effectiveXMin)

            // max가 전체 데이터 범위 이상이면 fitScreen으로 줌아웃 시작
            let visibleMax = xMap["max"] as? CGFloat
            let shouldZoomOut = visibleMax != nil && totalRange > 0 && Double(visibleMax!) >= totalRange

            if shouldZoomOut {
                // min 제약 리셋 후 fitScreen → 완전 줌아웃 보장
                barLineChart.setVisibleXRangeMinimum(0)
                barLineChart.fitScreen()
                // fitScreen 후에 min 설정 → 줌인 제한만 적용, 현재 뷰는 유지
                if let visibleMin = xMap["min"] as? CGFloat, visibleMin > 0 {
                    barLineChart.setVisibleXRangeMinimum(Double(visibleMin))
                }
            } else if let visibleMin = xMap["min"] as? CGFloat, visibleMin > 0 {
                if totalRange > Double(visibleMin) {
                    let relative = totalRange / Double(visibleMin)
                    let centerX: Double = effectiveXMax
                    let axis = barLineChart.getAxis(.left).isEnabled ? YAxis.AxisDependency.left : YAxis.AxisDependency.right
                    barLineChart.zoom(scaleX: relative, scaleY: 1.0, xValue: centerX, yValue: 0.0, axis: axis)
                } else if totalRange > 0 {
                    let relative = Double(visibleMin) / totalRange
                    let centerX: Double = effectiveXMax
                    let axis = barLineChart.getAxis(.left).isEnabled ? YAxis.AxisDependency.left : YAxis.AxisDependency.right
                    barLineChart.zoom(scaleX: CGFloat(relative), scaleY: 1.0, xValue: centerX, yValue: 0.0, axis: axis)
                }
            }
        }

        // Fire after one run-loop so viewPortHandler has updated with new visible range.
        DispatchQueue.main.async { [weak self] in
            self?.sendEvent("visibleRangeChanged")
        }
    }

    func setMaxScale(_ config: NSDictionary) {
        if config == NSNull() || config.count == 0 {
            barLineChart.viewPortHandler.setMaximumScaleX(CGFloat.greatestFiniteMagnitude)
            barLineChart.viewPortHandler.setMaximumScaleY(CGFloat.greatestFiniteMagnitude)
            return
        }
        let json = BridgeUtils.toJson(config)

        let maxScaleX = json["x"]
        if maxScaleX.double != nil {
            barLineChart.viewPortHandler.setMaximumScaleX(maxScaleX.doubleValue)
        }

        let maxScaleY = json["y"]
        if maxScaleY.double != nil {
            barLineChart.viewPortHandler.setMaximumScaleY(maxScaleY.doubleValue)
        }
    }

    func setAutoScaleMinMaxEnabled(_  enabled: Bool) {
        barLineChart.autoScaleMinMaxEnabled = enabled
    }

    func setKeepPositionOnRotation(_  enabled: Bool) {
        barLineChart.keepPositionOnRotation = enabled
    }

    func setScaleEnabled(_  enabled: Bool) {
        barLineChart.setScaleEnabled(enabled)
    }

    func setDragEnabled(_  enabled: Bool) {
        barLineChart.dragEnabled = enabled
    }


    func setScaleXEnabled(_  enabled: Bool) {
        barLineChart.scaleXEnabled = enabled
    }

    func setScaleYEnabled(_  enabled: Bool) {
        barLineChart.scaleYEnabled = enabled
    }

    func setPinchZoom(_  enabled: Bool) {
        barLineChart.pinchZoomEnabled = enabled
    }

    func setHighlightPerDragEnabled(_  enabled: Bool) {
        barLineChart.highlightPerDragEnabled = enabled
    }

    func setDoubleTapToZoomEnabled(_  enabled: Bool) {
        barLineChart.doubleTapToZoomEnabled = enabled
    }

    func setZoom(_ config: NSDictionary) {
        if config == NSNull() || config.count == 0 {
            // zoom 해제 → zoomScaleX 초기화
            self.zoomScaleX = nil
            self.savedZoom = nil
            return
        }
        self.savedZoom = config
        let json = BridgeUtils.toJson(config)
        if json["scaleX"].float != nil {
            self.zoomScaleX = CGFloat(json["scaleX"].floatValue)
        }
    }

    func updateZoom(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        if json["scaleX"].float != nil && json["scaleY"].float != nil && json["xValue"].double != nil && json["yValue"].double != nil {
            var axisDependency = YAxis.AxisDependency.left

            if json["axisDependency"].string != nil && json["axisDependency"].stringValue == "RIGHT" {
                axisDependency = YAxis.AxisDependency.right
            }

            barLineChart.zoom(scaleX: CGFloat(json["scaleX"].floatValue),
                    scaleY: CGFloat(json["scaleY"].floatValue),
                    xValue: json["xValue"].doubleValue,
                    yValue: json["yValue"].doubleValue,
                    axis: axisDependency)

            // Dispatch asynchronously to ensure matrix is updated before we read values.
            DispatchQueue.main.async { [weak self] in
                self?.sendEvent("zoomChanged")
            }
        }
    }

    func setViewPortOffsets(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        var left = json["left"].double != nil ? CGFloat(json["left"].doubleValue) : 0
        if left < 0 { left = 0 }
        let top = json["top"].double != nil ? CGFloat(json["top"].doubleValue) : 0
        let right = json["right"].double != nil ? CGFloat(json["right"].doubleValue) : 0
        let bottom = json["bottom"].double != nil ? CGFloat(json["bottom"].doubleValue) : 0

        barLineChart.setViewPortOffsets(left: left, top: top, right: right, bottom: bottom)
    }

    func setExtraOffsets(_ config: NSDictionary) {
        savedExtraOffsets = config
        applyExtraOffsets()
    }

    func applyExtraOffsets() {
        var left: CGFloat = 0
        var top: CGFloat = 0
        var right: CGFloat = 0
        var bottom: CGFloat = 0
        if let config = savedExtraOffsets {
            let json = BridgeUtils.toJson(config)
            left = json["left"].double != nil ? CGFloat(json["left"].doubleValue) : 0
            if left < 0 { left = 0 }
            top = json["top"].double != nil ? CGFloat(json["top"].doubleValue) : 0
            right = json["right"].double != nil ? CGFloat(json["right"].doubleValue) : 0
            bottom = json["bottom"].double != nil ? CGFloat(json["bottom"].doubleValue) : 0
        }
        let beforeBottomOffset = barLineChart.viewPortHandler.offsetBottom
        if edgeLabelEnabled {
            var axisHeight = barLineChart.xAxis.labelFont.lineHeight / 2
            if xAxisContainsNewline() {
                axisHeight = barLineChart.xAxis.labelFont.lineHeight
            }
            bottom += axisHeight + edgeLabelHeight() / 2
        }
        
        barLineChart.setExtraOffsets(left: left, top: top, right: right, bottom: bottom)
        barLineChart.notifyDataSetChanged()
    }

    private func xAxisContainsNewline() -> Bool {
        let axis = barLineChart.xAxis
        guard let formatter = axis.valueFormatter else { return false }
        let maxIdx = Int(axis.axisMaximum)
        for i in 0..<maxIdx {
            if formatter.stringForValue(Double(i), axis: axis).contains("\n") {
                return true
            }
        }
        return false
    }

    override func onAfterDataSetChanged() {
        super.onAfterDataSetChanged()

        applyExtraOffsets()

        // didSetProps에서 호출됨 → 모든 prop 업데이트 완료 후이므로 지연 불필요
        NSLog("[ChartZoom] onAfterDataSetChanged: savedVisibleRange=%@ zoomScaleX=%@ scaleX=%f minScaleX=%f maxScaleX=%f chartWidth=%f", 
            String(describing: savedVisibleRange), 
            String(describing: zoomScaleX), 
            barLineChart.scaleX, 
            barLineChart.viewPortHandler.minScaleX, 
            barLineChart.viewPortHandler.maxScaleX, 
            barLineChart.frame.width)

        // savedVisibleRange == nil → all 모드: 무조건 fitScreen + 이전 줌 초기화
        if savedVisibleRange == nil {
            zoomScaleX = nil
            if barLineChart.frame.width > 0 {
                // 차트가 레이아웃된 상태 → 즉시 줌아웃
                performFullZoomOut()
            } else {
                // frame.width=0 → 레이아웃 후 줌아웃
                needsFullZoomOut = true
                NSLog("[ChartZoom] onAfterDataSetChanged: frame.width=0, deferring zoom to layoutSubviews")
            }
        } else if let visibleRange = savedVisibleRange {
            updateVisibleRange(visibleRange)
        }

        if let zoom = savedZoom {
            updateZoom(zoom)
            savedZoom = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if needsFullZoomOut && barLineChart.frame.width > 0 {
            needsFullZoomOut = false
            NSLog("[ChartZoom] layoutSubviews: frame.width=%f, performing deferred zoomOut", barLineChart.frame.width)
            performFullZoomOut()
        }
    }

    private func performFullZoomOut() {
        // setMinimumScaleX()에 1.0 하한선 → KVC로 우회
        barLineChart.fitScreen()

        let vph = barLineChart.viewPortHandler
        guard let data = barLineChart.data else { return }

        let totalRange = data.xMax - data.xMin
        guard totalRange > 0 else { return }

        // fitScreen 후 scaleX=1.0에서 보이는 범위
        let visibleRange = barLineChart.highestVisibleX - barLineChart.lowestVisibleX
        NSLog("[ChartZoom] fitScreen: visibleRange=%f totalRange=%f scaleX=%f",
            visibleRange, totalRange, barLineChart.scaleX)

        // Charts 기준 fitScreen은 scaleX=1.0에서 이미 전체 데이터가 보인다고 판단하지만,
        // 실제 pinch gesture는 scaleX < 1.0까지 더 줌아웃된다.
        // 초기 상태도 제스처 가능한 최저 줌아웃에 맞춘다.
        let targetScaleX: CGFloat = 0.7

        // minScaleX를 targetScaleX 이하로 설정 (1.0 하한선 우회)
        let minScale = targetScaleX
        do {
            try vph.setValue(minScale, forKey: "minScaleX")
        } catch {
            NSLog("[ChartZoom] KVC set minScaleX failed: %@", error.localizedDescription)
        }

        // 줌아웃
        let currentScaleX = barLineChart.scaleX
        if currentScaleX > targetScaleX {
            let relativeScale = targetScaleX / currentScaleX
            let axis: YAxis.AxisDependency = barLineChart.leftAxis.isEnabled ? .left : .right
            barLineChart.zoom(scaleX: relativeScale, scaleY: 1.0, xValue: 0, yValue: 0.0, axis: axis)
        }
        NSLog("[ChartZoom] performFullZoomOut: scaleX=%f minScaleX=%f targetScaleX=%f visibleRange=%f totalRange=%f",
            barLineChart.scaleX, vph.minScaleX, targetScaleX, visibleRange, totalRange)
    }

    func setDataAndLockIndex(_ data: NSDictionary) {
        let json = BridgeUtils.toJson(data)

        let axis = barLineChart.getAxis(YAxis.AxisDependency.left).enabled ? YAxis.AxisDependency.left : YAxis.AxisDependency.right

        let contentRect = barLineChart.contentRect

        let originCenterValue = barLineChart.valueForTouchPoint(point: CGPoint(x: contentRect.midX, y: contentRect.midY), axis: axis)

        let originalVisibleXRange = barLineChart.visibleXRange
        let originalVisibleYRange = getVisibleYRange(axis)

        barLineChart.fitScreen()

        barLineChart.data = dataExtract.extract(json)
        barLineChart.notifyDataSetChanged()


        let newVisibleXRange = barLineChart.visibleXRange
        let newVisibleYRange = getVisibleYRange(axis)

        let scaleX = newVisibleXRange / originalVisibleXRange
        let scaleY = newVisibleYRange / originalVisibleYRange

        // in iOS Charts chart.zoom scaleX: CGFloat, scaleY: CGFloat, xValue: Double, yValue: Double, axis: YAxis.AxisDependency)
        // the scale is absolute scale, it will overwrite touchMatrix scale directly
        // but in android MpAndroidChart, ZoomJob getInstance(viewPortHandler, scaleX, scaleY, xValue, yValue, trans, axis, v)
        // the scale is relative scale, touchMatrix.scaleX = touchMatrix.scaleX * scaleX
        // so in iOS, we updateVisibleRange after zoom

        barLineChart.zoom(scaleX: CGFloat(scaleX), scaleY: CGFloat(scaleY), xValue: Double(originCenterValue.x), yValue: Double(originCenterValue.y), axis: axis)

        if let config = savedVisibleRange {
            updateVisibleRange(config)
        }
        barLineChart.notifyDataSetChanged()

        sendEvent("chartLoadComplete")
    }

    func getVisibleYRange(_ axis: YAxis.AxisDependency) -> CGFloat {
        let contentRect = barLineChart.contentRect

        return barLineChart.valueForTouchPoint(point: CGPoint(x: contentRect.maxX, y:contentRect.minY), axis: axis).y - barLineChart.valueForTouchPoint(point: CGPoint(x: contentRect.minX, y:contentRect.maxY), axis: axis).y
    }

    // func setLandscapeOrientation(_ enabled: Bool) {
        // Currently unused — layout for landscape mode is handled in JS.
        // Adding this setter prevents unknown-prop warnings on iOS.
    // }
}
