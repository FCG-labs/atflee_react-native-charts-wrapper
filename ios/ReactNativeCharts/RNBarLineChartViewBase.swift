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

    var savedExtraOffsets: NSDictionary?

    private var revealPending = false
    private var alphaBeforeReveal: CGFloat = 1.0
    private var revealGeneration = 0
    private let viewportRevealDelay: TimeInterval = 0.08

    var _onYaxisMinMaxChange : RCTDirectEventBlock?
    var timer : Timer?

    private func debugViewportState(_ phase: String) {
        #if DEBUG
        let dataSummary: String
        if let data = barLineChart.data {
            dataSummary = "xMin=\(data.xMin) xMax=\(data.xMax)"
        } else {
            dataSummary = "nil"
        }
        NSLog("[RNChartsViewportPoC] \(phase) alpha=\(barLineChart.alpha) revealPending=\(revealPending) generation=\(revealGeneration) data=\(dataSummary) bounds=\(barLineChart.bounds) visibleXRange=\(barLineChart.visibleXRange) scaleX=\(barLineChart.scaleX)")
        #endif
    }

    private func debugForceRevealIfStuck(_ phase: String) {
        #if DEBUG
        let generation = revealGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self = self else { return }
            if self.barLineChart.data != nil && self.barLineChart.alpha == 0 && self.revealPending && self.revealGeneration == generation {
                self.debugViewportState("forceReveal.before \(phase)")
                self.barLineChart.alpha = self.alphaBeforeReveal
                self.revealPending = false
                self.debugViewportState("forceReveal.after \(phase)")
            }
        }
        #endif
    }

    private func hideUntilViewportSettled() {
        if !revealPending {
            alphaBeforeReveal = barLineChart.alpha
        }
        revealPending = true
        revealGeneration += 1
        barLineChart.alpha = 0
        debugViewportState("hide")
    }

    private func revealAfterViewportSettled() {
        if !revealPending { return }
        let generation = revealGeneration
        debugViewportState("reveal.schedule")
        DispatchQueue.main.asyncAfter(deadline: .now() + viewportRevealDelay) { [weak self] in
            DispatchQueue.main.async { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if !(self.revealPending && self.revealGeneration == generation) {
                        self.debugViewportState("reveal.skip scheduledGeneration=\(generation)")
                        return
                    }
                    self.debugViewportState("reveal.before")
                    self.barLineChart.alpha = self.alphaBeforeReveal
                    self.revealPending = false
                    self.debugViewportState("reveal.after")
                    self.emitChartLoadCompleteIfReady()
                }
            }
        }
    }

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

    func setOnYaxisMinMaxChange(_ callback: RCTDirectEventBlock?) {
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


    func setMaxVisibleValueCount(_ count: CGFloat) {
        maxVisibleValueCountOverride = count > 0 ? count : nil
        barLineChart.maxVisibleCount = max(Int(ceil(count)), 0);
        updateValueVisibility(barLineChart)
    }

    func setVisibleRange(_ config: NSDictionary) {
        // delay visibleRange handling until chart data is set
        savedVisibleRange = config
        hideUntilViewportSettled()
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
        if x["min"].double != nil {
            let min = x["min"].doubleValue
            barLineChart.setVisibleXRangeMinimum(min)
        }
        if x["max"].double != nil {
            barLineChart.setVisibleXRangeMaximum(x["max"].doubleValue)
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

        if let target = zoomScaleX, target > 0 {
            if barLineChart.scaleX != target {
                let relative = target / barLineChart.scaleX
                let centerX = barLineChart.data?.xMax ?? 0
                let axis = barLineChart.getAxis(.left).isEnabled ? YAxis.AxisDependency.left : YAxis.AxisDependency.right
                barLineChart.zoom(scaleX: relative, scaleY: 1.0, xValue: centerX, yValue: 0.0, axis: axis)
            }
            // zoom prop이 명시적으로 있으면 auto-zoom 건너뜀
        } else if let saved = savedVisibleRange,
                  let xMap = saved["x"] as? NSDictionary,
                  let visibleMin = xMap["min"] as? CGFloat,
                  visibleMin > 0 {
            let rawDataXMin = barLineChart.data?.xMin ?? barLineChart.chartXMin
            let rawDataXMax = barLineChart.data?.xMax ?? barLineChart.chartXMax
            let effectiveXMin = min(rawDataXMin, barLineChart.chartXMin)
            let effectiveXMax = max(rawDataXMax, barLineChart.chartXMax)
            let totalRange = Double(effectiveXMax - effectiveXMin)

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

        // Fire after one run-loop so viewPortHandler has updated with new visible range.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateValueVisibility(self.barLineChart)
            self.sendEvent("visibleRangeChanged")
            self.revealAfterViewportSettled()
            self.emitChartLoadCompleteIfReady()
        }
    }

    func setMaxScale(_ config: NSDictionary) {
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

        let json = BridgeUtils.toJson(config)
        let hasCompleteZoomConfig =
            json["scaleX"].float != nil &&
            json["scaleY"].float != nil &&
            json["xValue"].double != nil &&
            json["yValue"].double != nil

        guard hasCompleteZoomConfig else {
            self.zoomScaleX = nil
            self.savedZoom = nil
            return
        }

        self.savedZoom = config
        hideUntilViewportSettled()

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
                guard let self = self else { return }
                self.updateValueVisibility(self.barLineChart)
                self.sendEvent("zoomChanged")
                self.revealAfterViewportSettled()
                self.emitChartLoadCompleteIfReady()
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
        if edgeLabelEnabled {
            bottom += max(edgeLabelHeight(), barLineChart.xAxis.labelFont.lineHeight) + barLineChart.xAxis.yOffset
        }
        if let marker = barLineChart.marker as? AtfleeMarker {
            top = max(top, marker.fixedTopReservedOffset)
        }
        
        barLineChart.setExtraOffsets(left: left, top: top, right: right, bottom: bottom)
        barLineChart.notifyDataSetChanged()
    }

    override func onBeforeDataSetChanged(_ data: NSDictionary) {
        super.onBeforeDataSetChanged(data)
        hideUntilViewportSettled()
    }

    override func onAfterDataSetChanged() {
        super.onAfterDataSetChanged()
        debugViewportState("after.begin")

        applyExtraOffsets()

        // clear zoom after applied, but keep visibleRange
        if let visibleRange = savedVisibleRange {
            hideUntilViewportSettled()
            updateVisibleRange(visibleRange)
        }

        if let zoom = savedZoom {
            hideUntilViewportSettled()
            updateZoom(zoom)
            savedZoom = nil
        } else if savedVisibleRange == nil {
            updateValueVisibility(barLineChart)
            revealAfterViewportSettled()
            emitChartLoadCompleteIfReady()
        }
        emitChartLoadCompleteAfterDataSetChanged()
        debugForceRevealIfStuck("after")
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

    @objc func fabricMoveViewToX(_ xValue: NSNumber) {
        barLineChart.moveViewToX(xValue.doubleValue)
    }

    @objc func fabricMoveViewTo(_ args: NSDictionary) {
        let json = BridgeUtils.toJson(args)
        barLineChart.moveViewTo(
            xValue: json["xValue"].doubleValue,
            yValue: json["yValue"].doubleValue,
            axis: BridgeUtils.parseAxisDependency(json["axisDependency"].stringValue)
        )
    }

    @objc func fabricMoveViewToAnimated(_ args: NSDictionary) {
        let json = BridgeUtils.toJson(args)
        barLineChart.moveViewToAnimated(
            xValue: json["xValue"].doubleValue,
            yValue: json["yValue"].doubleValue,
            axis: BridgeUtils.parseAxisDependency(json["axisDependency"].stringValue),
            duration: json["duration"].doubleValue / 1000.0
        )
    }

    @objc func fabricCenterViewTo(_ args: NSDictionary) {
        let json = BridgeUtils.toJson(args)
        barLineChart.centerViewTo(
            xValue: json["xValue"].doubleValue,
            yValue: json["yValue"].doubleValue,
            axis: BridgeUtils.parseAxisDependency(json["axisDependency"].stringValue)
        )
    }

    @objc func fabricCenterViewToAnimated(_ args: NSDictionary) {
        let json = BridgeUtils.toJson(args)
        barLineChart.centerViewToAnimated(
            xValue: json["xValue"].doubleValue,
            yValue: json["yValue"].doubleValue,
            axis: BridgeUtils.parseAxisDependency(json["axisDependency"].stringValue),
            duration: json["duration"].doubleValue / 1000.0
        )
    }

    @objc func fabricFitScreen() {
        barLineChart.fitScreen()
    }

    @objc func fabricHighlights(_ config: Any?) {
        setHighlights(config)
    }

    @objc func fabricSetDataAndLockIndex(_ data: NSDictionary) {
        setDataAndLockIndex(data)
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
