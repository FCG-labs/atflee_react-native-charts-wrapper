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

    var persistedZoom: NSDictionary?

    /// Android `ChartExtraProperties.zoomScaleX` parity — explicit zoom prop scaleX SSOT.
    var persistedZoomScaleX: CGFloat?

    /// Android `ChartExtraProperties.autoZoomPending` — visibleRange 변경 후 auto-zoom 1회.
    var autoZoomPending: Bool = false
    private var isHandlingLayoutSubviews = false
    private var hasQueuedValueLabelVisibilityRefresh = false

    var savedExtraOffsets: NSDictionary?

    var _onYaxisMinMaxChange : RCTDirectEventBlock?
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
        markLoadCompleteForResendIfNeeded()
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
        // Fabric: 초기 마운트(oldProps=nil)에서 JS 미설정 prop이 0으로 강제 dispatch된다.
        // maxHighlightDistance=0이면 closestSelectionDetailByPixel의 cDistance<0 비교가 항상 거짓이라
        // 탭 highlight를 못 잡는다(chartValueNothingSelected). 0/음수는 무시하고
        // DGCharts 기본값(500)을 유지한다(Paper parity).
        guard maxHighlightDistance > 0 else { return }
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
        restoreInitialXAxisLabelMode(barLineChart)
    }

    func setVisibleRange(_ config: NSDictionary) {
        // delay visibleRange handling until chart data is set
        savedVisibleRange = config
        autoZoomPending = true
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

        applyVisibleRangeZoomPolicy(json)

        // Fire after one run-loop so viewPortHandler has updated with new visible range.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.restoreInitialXAxisLabelMode(self.barLineChart)
            self.sendEvent("visibleRangeChanged")
        }
    }

    /// Android `BarLineChartBaseManager.updateVisibleRange` zoom branches — explicit scaleX 우선, 없으면 visibleRange.x.min auto-zoom.
    private func applyVisibleRangeZoomPolicy(_ json: JSON) {
        guard isReadyToApplyZoom() else { return }

        let axis: YAxis.AxisDependency = barLineChart.leftAxis.enabled ? .left : .right

        if let targetScale = persistedZoomScaleX, targetScale > 0 {
            let currentScale = max(barLineChart.scaleX, 0.00001)
            if abs(barLineChart.scaleX - targetScale) > 0.0001 {
                let centerX = barLineChart.data?.xMax ?? barLineChart.chartXMax
                barLineChart.zoom(
                    scaleX: targetScale / currentScale,
                    scaleY: 1,
                    xValue: centerX,
                    yValue: 0,
                    axis: axis
                )
            }
            autoZoomPending = false
            refreshValueLabelVisibility()
            return
        }

        guard autoZoomPending else { return }

        let visibleMin = json["x"]["min"].double
        guard let visibleMin, visibleMin > 0 else {
            autoZoomPending = false
            return
        }

        let rawDataXMin = barLineChart.data?.xMin ?? barLineChart.chartXMin
        let rawDataXMax = barLineChart.data?.xMax ?? barLineChart.chartXMax
        let effectiveXMin = min(rawDataXMin, barLineChart.chartXMin)
        let effectiveXMax = max(rawDataXMax, barLineChart.chartXMax)
        let totalRange = effectiveXMax - effectiveXMin
        guard totalRange > 0 else {
            autoZoomPending = false
            return
        }

        barLineChart.xAxis.axisMinimum = effectiveXMin
        barLineChart.xAxis.axisMaximum = effectiveXMax
        barLineChart.setVisibleXRangeMinimum(visibleMin)
        if json["x"]["max"].double != nil {
            barLineChart.setVisibleXRangeMaximum(json["x"]["max"].doubleValue)
        }

        let targetScale = totalRange > visibleMin
            ? CGFloat(totalRange / visibleMin)
            : CGFloat(visibleMin / totalRange)
        let currentScale = max(barLineChart.scaleX, 0.00001)
        let relativeScale = targetScale / currentScale
        let centerX = effectiveXMax - visibleMin / 2.0
        barLineChart.zoom(
            scaleX: relativeScale,
            scaleY: 1,
            xValue: centerX,
            yValue: 0,
            axis: axis
        )
        barLineChart.moveViewToX(max(effectiveXMax - visibleMin, effectiveXMin))
        let expectedScale = targetScale
        if abs(barLineChart.scaleX - expectedScale) > max(expectedScale * 0.05, 0.01) {
            // viewport/layout 레이스 — layoutSubviews 에서 재시도
            autoZoomPending = true
        } else {
            autoZoomPending = false
        }
        refreshValueLabelVisibility()
    }

    /// Android `RNOnChartGestureListener.adjustValueAndEdgeLabels` — programmatic zoom 후 chartScaled 미발화 보정.
    func refreshValueLabelVisibility() {
        if isHandlingLayoutSubviews {
            queueValueLabelVisibilityRefresh()
            return
        }
        restoreInitialXAxisLabelMode(barLineChart)
    }

    func performLayoutSubviewsUpdates(_ updates: () -> Void) {
        isHandlingLayoutSubviews = true
        defer { isHandlingLayoutSubviews = false }
        updates()
    }

    private func queueValueLabelVisibilityRefresh() {
        guard !hasQueuedValueLabelVisibilityRefresh else { return }
        hasQueuedValueLabelVisibilityRefresh = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hasQueuedValueLabelVisibilityRefresh = false
            self.refreshValueLabelVisibility()
        }
    }

    func applyVisibleRangeWhenReady() {
        guard let config = savedVisibleRange else { return }
        guard barLineChart.data != nil else { return }
        if !isReadyToApplyZoom() { return }
        if autoZoomPending || persistedZoomScaleX != nil {
            applyVisibleRangeZoomPolicy(BridgeUtils.toJson(config))
        } else {
            refreshValueLabelVisibility()
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
            self.persistedZoom = nil
            self.savedZoom = nil
            self.persistedZoomScaleX = nil
            return
        }

        let json = BridgeUtils.toJson(config)
        let hasCompleteZoomConfig =
            json["scaleX"].float != nil &&
            json["scaleY"].float != nil &&
            json["xValue"].double != nil &&
            json["yValue"].double != nil

        guard hasCompleteZoomConfig else {
            self.persistedZoom = nil
            self.savedZoom = nil
            self.persistedZoomScaleX = nil
            return
        }

        self.persistedZoom = config
        self.persistedZoomScaleX = CGFloat(json["scaleX"].floatValue)

        // Fabric: data가 있어도 viewport/chart dimens가 아직 0이면 zoom()이 무시될 수 있다.
        // 이 시점에 savedZoom을 소비해버리면 초기 렌더가 fit-all(scaleX=1)로 남는다.
        // viewport 준비 전에는 저장만 하고, layoutSubviews/onAfterDataSetChanged에서 1회 적용한다.
        guard isReadyToApplyZoom() else {
            self.savedZoom = config
            return
        }

        self.savedZoom = nil
        applyZoomFromConfig(config)
    }

    private func isReadyToApplyZoom() -> Bool {
        let handler = barLineChart.viewPortHandler
        return barLineChart.data != nil
            && barLineChart.bounds.width > 0
            && barLineChart.bounds.height > 0
            && handler.chartWidth > 0
            && handler.chartHeight > 0
            && handler.contentWidth > 0
            && handler.contentHeight > 0
    }

    func applySavedZoomIfReady() {
        guard let zoom = savedZoom, isReadyToApplyZoom() else { return }
        savedZoom = nil
        applyZoomFromConfig(zoom)
    }

    /// Android `BarLineChartBaseManager.setZoom` parity — MPAndroidChart uses relative scale factors.
    private func applyZoomFromConfig(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        guard json["scaleX"].float != nil,
              json["scaleY"].float != nil,
              json["xValue"].double != nil,
              json["yValue"].double != nil else {
            return
        }

        let targetScaleX = CGFloat(json["scaleX"].floatValue)
        let targetScaleY = CGFloat(json["scaleY"].floatValue)
        let currentScaleX = max(barLineChart.scaleX, 0.00001)
        let currentScaleY = max(barLineChart.scaleY, 0.00001)

        var axisDependency = YAxis.AxisDependency.left
        if json["axisDependency"].string != nil && json["axisDependency"].stringValue == "RIGHT" {
            axisDependency = YAxis.AxisDependency.right
        }

        barLineChart.zoom(
            scaleX: targetScaleX / currentScaleX,
            scaleY: targetScaleY / currentScaleY,
            xValue: json["xValue"].doubleValue,
            yValue: json["yValue"].doubleValue,
            axis: axisDependency
        )
        persistedZoomScaleX = targetScaleX

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.restoreInitialXAxisLabelMode(self.barLineChart)
            self.sendEvent("zoomChanged")
        }
    }

    func updateZoom(_ config: NSDictionary) {
        applyZoomFromConfig(config)
    }

    func setViewPortOffsets(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        // Fabric: 초기 마운트(oldProps=nil)에서는 JS가 주지 않은 viewPortOffsets({})도 강제 dispatch된다.
        // 빈 값으로 setViewPortOffsets를 호출하면 DGCharts가 _customViewPortEnabled=true로 잠겨
        // calculateOffsets(축 라벨/extraOffsets 여백)가 통째로 skip되고, offset이 0으로 고정되어
        // x축·우측 y축 라벨이 사라진다. 키가 하나도 없으면 customViewPort를 켜지 않는다(Paper parity).
        let hasAny = json["left"].double != nil || json["top"].double != nil
            || json["right"].double != nil || json["bottom"].double != nil
        guard hasAny else { return }

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

    /// Android `BarLineChartBaseManager.onAfterDataSetChanged` — savedVisibleRange 가 있으면 매 prop tick viewport 재적용.
    func reapplySavedVisibleRangeViewport() {
        guard let config = savedVisibleRange else { return }
        if persistedZoomScaleX == nil {
            autoZoomPending = true
        }
        updateVisibleRange(config)
    }

    private var lastAppliedDataEntryCount: Int = -1

    override func onAfterDataSetChanged() {
        super.onAfterDataSetChanged()

        applyExtraOffsets()

        let entryCount = Int(barLineChart.data?.entryCount ?? 0)
        let dataChanged = entryCount != lastAppliedDataEntryCount
        if dataChanged {
            lastAppliedDataEntryCount = entryCount
        }

        if savedVisibleRange != nil {
            reapplySavedVisibleRangeViewport()
        } else if dataChanged {
            restoreInitialXAxisLabelMode(barLineChart)
        }

        if dataChanged, let zoom = persistedZoom {
            savedZoom = zoom
        }

        applySavedZoomIfReady()
        applyVisibleRangeWhenReady()

        barLineChart.setNeedsDisplay()
        emitChartLoadCompleteIfReady()
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
