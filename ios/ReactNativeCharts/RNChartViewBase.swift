//
//  RNChartViewBase.swift
//  reactNativeCharts
//
//  Created by xudong wu on 25/02/2017.
//  Copyright wuxudong
//

import UIKit
import DGCharts
import SwiftyJSON
import ObjectiveC

// Associated-object key for caching initial drawValues flag
private var baseDrawValuesKey: UInt8 = 0

// In react native, because object-c is unaware of swift protocol extension. use baseClass as workaround

// 파일 상단 또는 RNChartViewBase 클래스 외부에 정의
final class OverlayMarkerButton: UIButton {
    var clickHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    @objc private func handleTap() {
        clickHandler?()
    }
}

@objcMembers
open class RNChartViewBase: UIView, ChartViewDelegate {
    open var onSelect:RCTBubblingEventBlock?

    open var onChange:RCTBubblingEventBlock?

    open var onMarkerClick: RCTBubblingEventBlock?

    private var leftEdgeLabel: UILabel?
    private var rightEdgeLabel: UILabel?
    private var leftEdgeLabelHasNewline = false
    private var rightEdgeLabelHasNewline = false
    private var leftEdgeConstraint: NSLayoutConstraint?
    private var rightEdgeConstraint: NSLayoutConstraint?
    var edgeLabelEnabled: Bool = false
    // whether edgeLabelEnabled was explicitly provided from JS; nil means auto
    private var edgeLabelExplicit: Bool? = nil
    // remembers initial xAxis.drawLabelsEnabled when provided via JS
    private var userXAxisDrawLabels: Bool? = nil
    let edgeLabelTopPadding: CGFloat = 0
    // optional override from JS. nil means auto.
    @objc var landscapeOrientation: Bool = false {
        didSet {
            let v = landscapeOrientation
            landscapeOrientationOverride = v
            updateValueVisibility(chart)
        }
    }
    var landscapeOrientationOverride: Bool? = nil

    private var group: String?

    private  var identifier: String?

    private  var syncX = true

    private  var syncY = false

    private var hasSentLoadComplete = false

    override open func layoutSubviews() {
        super.layoutSubviews()

        if edgeLabelEnabled, let bar = self as? RNBarLineChartViewBase {
            bar.applyExtraOffsets()
        }

        if !hasSentLoadComplete && bounds.width > 0 && bounds.height > 0 {
            DispatchQueue.main.async {
                CATransaction.flush()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.sendEvent("chartLoadComplete")
                    self.hasSentLoadComplete = true
                }
            }
        }
    }

    override open func reactSetFrame(_ frame: CGRect)
    {
        super.reactSetFrame(frame);

        let chartFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        // Ensure bar charts have half-bar spacing so first/last bars are fully visible.
        if let barProvider = chart as? BarChartDataProvider,
           let barData = barProvider.barData {
            let bw = barData.barWidth
            chart.xAxis.spaceMin = 0.75
            chart.xAxis.spaceMax = 0.35
        } else {
            chart.xAxis.spaceMin = 0.75
            chart.xAxis.spaceMax = 0.75
        }
        chart.reactSetFrame(chartFrame)
    }

    var chart: ChartViewBase {
        fatalError("subclass should override this function.")
    }

    var dataExtract : DataExtract {
        fatalError("subclass should override this function.")
    }

    func setData(_ data: NSDictionary) {
        let json = BridgeUtils.toJson(data)

        let extractedChartData: ChartData? = dataExtract.extract(json)

        guard let chartData = extractedChartData else { return }

        // https://github.com/danielgindi/Charts/issues/4690
        let originValueFormatters = chartData.map {$0.valueFormatter}

        chart.data = chartData

        for (set, valueFormatter) in zip(chartData, originValueFormatters) {
            set.valueFormatter = valueFormatter
        }
    }

    func setLegend(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        let legend = chart.legend;

        if json["enabled"].bool != nil {
            legend.enabled = json["enabled"].boolValue;
        }

        if json["textColor"].int != nil {
            legend.textColor = RCTConvert.uiColor(json["textColor"].intValue);
        }

        if json["textSize"].number != nil {
            legend.font = legend.font.withSize(CGFloat(truncating: json["textSize"].numberValue))
        }

        // Wrapping / clipping avoidance
        if json["wordWrapEnabled"].bool != nil {
            legend.wordWrapEnabled = json["wordWrapEnabled"].boolValue
        }

        if json["maxSizePercent"].number != nil {
            legend.maxSizePercent = CGFloat(truncating: json["maxSizePercent"].numberValue)
        }

        if json["horizontalAlignment"].string != nil {
            legend.horizontalAlignment = BridgeUtils.parseLegendHorizontalAlignment(json["horizontalAlignment"].stringValue)
        }

        if json["verticalAlignment"].string != nil {
            legend.verticalAlignment = BridgeUtils.parseLegendVerticalAlignment(json["verticalAlignment"].stringValue)
        }

        if json["orientation"].string != nil {
            legend.orientation = BridgeUtils.parseLegendOrientation(json["orientation"].stringValue)
        }

        if json["drawInside"].bool != nil {
            legend.drawInside = json["drawInside"].boolValue
        }

        if json["direction"].string != nil {
            legend.direction = BridgeUtils.parseLegendDirection(json["direction"].stringValue)
        }

        if let font = FontUtils.getFont(json) {
            legend.font = font
        }

        if json["form"].string != nil {
            legend.form = BridgeUtils.parseLegendForm(json["form"].stringValue)
        }

        if json["formSize"].number != nil {
            legend.formSize = CGFloat(truncating: json["formSize"].numberValue)
        }

        if json["xEntrySpace"].number != nil {
            legend.xEntrySpace = CGFloat(truncating: json["xEntrySpace"].numberValue)
        }

        if json["yEntrySpace"].number != nil {
            legend.yEntrySpace = CGFloat(truncating: json["yEntrySpace"].numberValue)
        }

        if json["formToTextSpace"].number != nil {
            legend.formToTextSpace = CGFloat(truncating: json["formToTextSpace"].numberValue)
        }

        // Custom labels & colors
        if json["custom"].exists() {
            let customMap = json["custom"]
            if customMap["colors"].exists() && customMap["labels"].exists() {

                let colorsArray = customMap["colors"].arrayValue
                let labelsArray = customMap["labels"].arrayValue

                if colorsArray.count == labelsArray.count {
                    // TODO null label should start a group
                    // TODO -2 color should avoid drawing a form

                    var legendEntries = [LegendEntry]();

                    for i in 0..<labelsArray.count {
                        let legendEntry = LegendEntry()
                        legendEntry.formColor =  RCTConvert.uiColor(colorsArray[i].intValue);
                        legendEntry.label = labelsArray[i].stringValue;

                        legendEntries.append(legendEntry)
                    }

                    legend.setCustom(entries: legendEntries)
                }
            }
        }

        // TODO extra

    }

    func setChartBackgroundColor(_ backgroundColor: Int) {
        chart.backgroundColor = RCTConvert.uiColor(backgroundColor)
    }

    func setChartDescription(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        let chartDescription = Description()

        if json["text"].string != nil {
            chartDescription.text = json["text"].stringValue
        }

        if json["textColor"].int != nil {
            chartDescription.textColor = RCTConvert.uiColor(json["textColor"].intValue)
        }

        if json["textSize"].float != nil {
            chartDescription.font = chartDescription.font.withSize(CGFloat(json["textSize"].floatValue))
        }

        if json["positionX"].number != nil && json["positionY"].number != nil {
            chartDescription.position = CGPoint(x: CGFloat(truncating: json["positionX"].numberValue), y: CGFloat(truncating: json["positionY"].numberValue))
        }

        chart.chartDescription = chartDescription
    }

    func setNoDataText(_ noDataText: String) {
        chart.noDataText = noDataText
    }

    func setNoDataTextColor(_ color: Int) {
        chart.noDataTextColor = RCTConvert.uiColor(color)
    }

    func setTouchEnabled(_ touchEnabled: Bool) {
        chart.isUserInteractionEnabled = touchEnabled
    }

    func setHighlightPerTapEnabled(_ enabled: Bool) {
        chart.highlightPerTapEnabled = enabled
    }

    func setDragDecelerationEnabled(_ dragDecelerationEnabled: Bool) {
        chart.dragDecelerationEnabled = dragDecelerationEnabled
    }

    func setDragDecelerationFrictionCoef(_ dragDecelerationFrictionCoef: NSNumber) {
        chart.dragDecelerationFrictionCoef = CGFloat(truncating: dragDecelerationFrictionCoef)
    }

    func setAnimation(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        let durationX = json["durationX"].double != nil ?
            json["durationX"].doubleValue / 1000.0 : 0
        let durationY = json["durationY"].double != nil ?
            json["durationY"].doubleValue / 1000.0 : 0


        var easingX: ChartEasingOption = .linear
        var easingY: ChartEasingOption = .linear

        if json["easingX"].string != nil {
            easingX = BridgeUtils.parseEasingOption(json["easingX"].stringValue)
        }
        if json["easingY"].string != nil {
            easingY = BridgeUtils.parseEasingOption(json["easingY"].stringValue)
        }

        if durationX != 0 && durationY != 0 {
            chart.animate(xAxisDuration: durationX, yAxisDuration: durationY, easingOptionX: easingX, easingOptionY: easingY)
        } else if (durationX != 0) {
            chart.animate(xAxisDuration: durationX, easingOption: easingX)
        } else if (durationY != 0) {
            chart.animate(yAxisDuration: durationY, easingOption: easingY)
        }
    }

    func setXAxis(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        let xAxis = chart.xAxis;

        setCommonAxisConfig(xAxis, config: json)

        if json["drawLabels"].bool != nil {
            userXAxisDrawLabels = json["drawLabels"].boolValue
        }

        if json["labelRotationAngle"].number != nil {
            xAxis.labelRotationAngle = CGFloat(truncating: json["labelRotationAngle"].numberValue)
        }

        if json["avoidFirstLastClipping"].bool != nil {
            xAxis.avoidFirstLastClippingEnabled = json["avoidFirstLastClipping"].boolValue
        }

        if json["position"].string != nil {
            xAxis.labelPosition = BridgeUtils.parseXAxisLabelPosition(json["position"].stringValue)
        }

        let provided = json["edgeLabelEnabled"].bool
        // remember explicit flag (true/false) or nil if not supplied
        edgeLabelExplicit = provided
        var enable: Bool
        if let explicit = provided {
            enable = explicit
        } else {
            // 자동 결정: 라벨에 개행이 없으면 edgeLabel 사용, 있으면 기본 라벨 사용
            // enable = !axisLabelsContainNewline(axis: xAxis)

            // 기본값: 초기에는 edge label 끔. 이후 zoom 변화에 따라 updateValueVisibility()에서 자동 토글
            enable = false
        }
        xAxis.drawLabelsEnabled = !enable
        configureEdgeLabels(enable)
    }

    func setCommonAxisConfig(_ axis: AxisBase, config: JSON) {

        // what is drawn
        if config["enabled"].bool != nil {
            axis.enabled = config["enabled"].boolValue
        }

        if config["drawLabels"].bool != nil {
            axis.drawLabelsEnabled = config["drawLabels"].boolValue
        }

        if config["drawAxisLine"].bool != nil {
            axis.drawAxisLineEnabled = config["drawAxisLine"].boolValue
        }

        if config["drawGridLines"].bool != nil {
            axis.drawGridLinesEnabled = config["drawGridLines"].boolValue
        }

        // style
        if let font = FontUtils.getFont(config) {
            axis.labelFont  = font
        }

        if config["textColor"].int != nil {
            axis.labelTextColor = RCTConvert.uiColor(config["textColor"].intValue)
        }

        if config["textSize"].float != nil {
            axis.labelFont = axis.labelFont.withSize(CGFloat(config["textSize"].floatValue))
        }

        if config["yOffset"].number != nil {
            axis.yOffset = CGFloat(truncating: config["yOffset"].numberValue)
        }

        if config["gridColor"].int != nil {
            axis.gridColor = RCTConvert.uiColor(config["gridColor"].intValue)
        }

        if config["gridLineWidth"].number != nil {
            axis.gridLineWidth = CGFloat(truncating: config["gridLineWidth"].numberValue)
        }

        if config["axisLineColor"].int != nil {
            axis.axisLineColor = RCTConvert.uiColor(config["axisLineColor"].intValue)
        }

        if config["axisLineWidth"].number != nil {
            axis.axisLineWidth = CGFloat(truncating: config["axisLineWidth"].numberValue)
        }

        if config["gridDashedLine"].exists() {
            let gridDashedLine = config["gridDashedLine"]

            var lineLength = CGFloat(0)
            var spaceLength = CGFloat(0)

            if gridDashedLine["lineLength"].number != nil {
                lineLength = CGFloat(truncating: gridDashedLine["lineLength"].numberValue)
            }

            if gridDashedLine["spaceLength"].number != nil {
                spaceLength = CGFloat(truncating: gridDashedLine["spaceLength"].numberValue)
            }

            if gridDashedLine["phase"].number != nil {
                axis.gridLineDashPhase = CGFloat(truncating: gridDashedLine["phase"].numberValue)
            }

            axis.gridLineDashLengths = [lineLength, spaceLength]
        }

        // limit lines
        if config["limitLines"].array != nil {
            let limitLinesConfig = config["limitLines"].arrayValue

            axis.removeAllLimitLines()
            for limitLineConfig in limitLinesConfig {

                if limitLineConfig["limit"].double != nil {

                    let limitLine = ChartLimitLine(limit: limitLineConfig["limit"].doubleValue)

                    if limitLineConfig["label"].string != nil {
                        limitLine.label = limitLineConfig["label"].stringValue
                    }

                    if (limitLineConfig["lineColor"].int != nil) {
                        limitLine.lineColor = RCTConvert.uiColor(limitLineConfig["lineColor"].intValue)
                    }

                    if (limitLineConfig["valueTextColor"].int != nil) {
                        limitLine.valueTextColor = RCTConvert.uiColor(limitLineConfig["valueTextColor"].intValue)
                    }

                    let fontSize = limitLineConfig["valueFont"].int != nil ? CGFloat(limitLineConfig["valueFont"].intValue) : CGFloat(13)

                    if let parsedFont = FontUtils.getFont(limitLineConfig) {
                        limitLine.valueFont = RCTFont.update(parsedFont, withSize: NSNumber(value: Float(fontSize)))
                    } else {
                        limitLine.valueFont = NSUIFont.systemFont(ofSize: fontSize)
                    }

                    if limitLineConfig["lineWidth"].number != nil {
                        limitLine.lineWidth = CGFloat(truncating: limitLineConfig["lineWidth"].numberValue)
                    }

                    if limitLineConfig["labelPosition"].string != nil {
                        limitLine.labelPosition = BridgeUtils.parseLimitlineLabelPosition(limitLineConfig["labelPosition"].stringValue);
                    }

                    if limitLineConfig["lineDashPhase"].float != nil {
                        limitLine.lineDashPhase = CGFloat(limitLineConfig["lineDashPhase"].floatValue);
                    }
                    if limitLineConfig["lineDashLengths"].arrayObject != nil {
                        limitLine.lineDashLengths = limitLineConfig["lineDashLengths"].arrayObject as? [CGFloat];
                    }

                    axis.addLimitLine(limitLine)
                }
            }
        }

        if config["drawLimitLinesBehindData"].bool != nil {
            axis.drawLimitLinesBehindDataEnabled = config["drawLimitLinesBehindData"].boolValue
        }

        if config["axisMaximum"].double != nil {
            axis.axisMaximum = config["axisMaximum"].doubleValue
        }

        if config["axisMinimum"].double != nil {
            axis.axisMinimum = config["axisMinimum"].doubleValue
        }

        if config["granularity"].double != nil {
            axis.granularity = config["granularity"].doubleValue
        }

        if config["granularityEnabled"].bool != nil {
            axis.granularityEnabled = config["granularityEnabled"].boolValue
        }

        if config["labelCount"].int != nil {
            var labelCountForce = false
            if config["labelCountForce"].bool != nil {
                labelCountForce = config["labelCountForce"].boolValue
            }
            axis.setLabelCount(config["labelCount"].intValue, force: labelCountForce)
        }

        // formatting
        // TODO: other formatting options
        let valueFormatter = config["valueFormatter"];
        if valueFormatter.array != nil {
            axis.valueFormatter = IndexAxisValueFormatter(values: valueFormatter.arrayValue.map({ $0.stringValue }))
        } else if valueFormatter.string != nil {
            if "largeValue" == valueFormatter.stringValue {
                axis.valueFormatter = LargeValueFormatter();
            } else if "percent" == valueFormatter.stringValue {
                let percentFormatter = NumberFormatter()
                percentFormatter.numberStyle = .percent

                axis.valueFormatter = DefaultAxisValueFormatter(formatter: percentFormatter);
            } else if "date" == valueFormatter.stringValue {
              let valueFormatterPattern = config["valueFormatterPattern"].stringValue;
              let since = config["since"].double != nil ? config["since"].doubleValue : 0
              let timeUnit = config["timeUnit"].string != nil ? config["timeUnit"].stringValue : "MILLISECONDS"
              let locale = config["locale"].string;
              axis.valueFormatter = CustomChartDateFormatter(pattern: valueFormatterPattern, since: since, timeUnit: timeUnit, locale: locale);
            } else {
              let customFormatter = NumberFormatter()
              customFormatter.positiveFormat = valueFormatter.stringValue
              customFormatter.negativeFormat = valueFormatter.stringValue

              axis.valueFormatter = DefaultAxisValueFormatter(formatter: customFormatter);
          }
        }

        if config["centerAxisLabels"].bool != nil {
            axis.centerAxisLabelsEnabled = config["centerAxisLabels"].boolValue
        }
    }

    func setMarker(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        if json["enabled"].exists() && !json["enabled"].boolValue {
            chart.marker = nil
            return
        }

        var markerFont = UIFont.systemFont(ofSize: 12.0)

        if json["textSize"].float != nil {
            markerFont = markerFont.withSize(CGFloat(json["textSize"].floatValue))
        }
        switch (json["markerType"].string) {
        case "circle":
            let marker = CircleMarker(
                color: RCTConvert.uiColor(json["markerColor"].intValue),
                strokeColor: RCTConvert.uiColor(json["markerStrokeColor"].intValue),
                size: CGSize(
                    width: json["markerSize"].intValue,
                    height: json["markerSize"].intValue
                ),
                strokeSize: json["markerStrokeSize"].intValue
            )
            chart.marker = marker
            marker.chartView = chart
        case "atflee":
            var titleFont = UIFont.systemFont(ofSize: 12.0)
            if json["titleSize"].float != nil {
                titleFont = titleFont.withSize(CGFloat(json["titleSize"].floatValue))
            }

            let marker = AtfleeMarker(
                color: RCTConvert.uiColor(json["markerColor"].intValue),
                font: markerFont,
                textColor: RCTConvert.uiColor(json["textColor"].intValue),
                textAlign: RCTConvert.nsTextAlignment(json["textAlign"].stringValue),
                textWeight: (json["textWeight"].string ?? "normal").lowercased(),
                titleFont: titleFont
            )

            if json["arrowHidden"].bool != nil {
                marker.arrowHidden = json["arrowHidden"].boolValue
            }
            if json["fixedOnTop"].bool != nil {
                marker.fixedOnTop = json["fixedOnTop"].boolValue
            }

            chart.marker = marker
            marker.chartView = chart
        default:
            let marker = BalloonMarker(
                color: RCTConvert.uiColor(json["markerColor"].intValue),
                font: markerFont,
                textColor: RCTConvert.uiColor(json["textColor"].intValue),
                textAlign: RCTConvert.nsTextAlignment(json["textAlign"].stringValue)
            )
            chart.marker = marker
            marker.chartView = chart
        }
    }

    func setHighlights(_ config: NSArray) {
        chart.highlightValues(HighlightUtils.getHighlights(config))
    }

    @objc public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
        chartView.subviews
            .filter { $0.tag == 999 }
            .forEach { $0.removeFromSuperview() }
        
        if self.onSelect == nil {
            return
        } else {
            self.onSelect!(EntryToDictionaryUtils.entryToDictionary(entry))
        }
    }

    @objc public func chartValueNothingSelected(_ chartView: ChartViewBase) {
        self.onSelect?(nil)  // 아무것도 선택되지 않음
        
        chartView.subviews
            .filter { $0.tag == 999 }
            .forEach { $0.removeFromSuperview() }
    }
    
    @objc public func chartScaled(_ chartView: ChartViewBase, scaleX: CoreGraphics.CGFloat, scaleY: CoreGraphics.CGFloat) {
        sendEvent("chartScaled")
        updateValueVisibility(chartView)
        chartView.subviews
            .filter { $0.tag == 999 }
            .forEach { $0.removeFromSuperview() }
    }

    @objc public func chartTranslated(_ chartView: ChartViewBase, dX: CoreGraphics.CGFloat, dY: CoreGraphics.CGFloat) {
        sendEvent("chartTranslated")
        updateValueVisibility(chartView)
        chartView.subviews
            .filter { $0.tag == 999 }
            .forEach { $0.removeFromSuperview() }
    }

    @objc public func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        sendEvent("chartPanEnd")
        // 이건 좌우스크롤 highlightPerDragEnabled과 연관있으므로, 오버레이 터치 삭제하면 안됨
    }

    // MARK: - Value text / Edge label visibility based on zoom
    private func updateValueVisibility(_ chartView: ChartViewBase) {
        guard let barLine = chartView as? BarLineChartViewBase else { return }

        let isLandscape = landscapeOrientationOverride ?? (barLine.bounds.width > barLine.bounds.height)

        // 1. Decide whether to display value texts based on number of visible entries
        var leftIdx = Int(ceil(barLine.lowestVisibleX))
        var rightIdx = Int(floor(barLine.highestVisibleX))
        var visibleCount = rightIdx - leftIdx + 1
        if visibleCount < 0 { visibleCount = 0 }

        let threshold = isLandscape ? 15 : 8
        let showValues = visibleCount <= threshold

        if let data = barLine.data {
            // Remember each dataset's initial drawValuesEnabled setting and respect it.
            data.dataSets.forEach { set in
                // 1. Fetch or store the base flag once using associated objects.
                let baseDraw: Bool = {
                    if let num = objc_getAssociatedObject(set, &baseDrawValuesKey) as? NSNumber {
                        return num.boolValue
                    } else {
                        let initial = set.drawValuesEnabled
                        objc_setAssociatedObject(set, &baseDrawValuesKey, NSNumber(value: initial), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                        return initial
                    }
                }()

                // 2. If the user originally disabled value labels, keep them off permanently.
                if !baseDraw {
                    if set.drawValuesEnabled {
                        set.drawValuesEnabled = false
                    }
                    return
                }

                // 3. Otherwise, toggle according to zoom threshold.
                if set.drawValuesEnabled != showValues {
                    set.drawValuesEnabled = showValues
                }
            }
        }

        // 2. Determine desired edge-label state following USER rules
        let userDisabledLabels = (userXAxisDrawLabels == false)
        var desiredEdge: Bool

        if let explicit = edgeLabelExplicit {
            // explicit flag from JS wins unless labels disabled by user
            desiredEdge = userDisabledLabels ? true : explicit
        } else {
            // automatic: if labels disabled show edge label, else toggle with zoom
            desiredEdge = userDisabledLabels ? true : !showValues
        }

        // 3. Choose axis label visibility based on edge label state
        let showAxis = desiredEdge ? false : showValues
        // Update xAxis label visibility unless the user explicitly disabled labels (drawLabels: false)
        if edgeLabelExplicit == nil && !userDisabledLabels {
            barLine.xAxis.drawLabelsEnabled = showAxis
        }

        // 4. Apply edge label change only if needed
        if desiredEdge != edgeLabelEnabled {
            configureEdgeLabels(desiredEdge)
        }

        barLine.setNeedsDisplay()
    }

    /// Returns true if any xAxis valueFormatter label contains a newline.
    private func axisLabelsContainNewline(axis: XAxis) -> Bool {
        guard let formatter = axis.valueFormatter else { return false }
        let maxIdx = Int(axis.axisMaximum)
        let formatterCount = (formatter as? IndexAxisValueFormatter)?.values.count ?? 0
        let upper = max(maxIdx, formatterCount)
        for i in 0..<upper {
            if formatter.stringForValue(Double(i), axis: axis).contains("\n") {
                return true
            }
        }
        return false
    }

    private func configureEdgeLabels(_ enable: Bool) {
        edgeLabelEnabled = enable
        if enable {
            if let barLine = chart as? BarLineChartViewBase {
                barLine.xAxis.drawLabelsEnabled = false
            }
            if leftEdgeLabel == nil {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                addSubview(label)
                leftEdgeConstraint = label.topAnchor.constraint(equalTo: bottomAnchor, constant: -edgeLabelTopPadding)
                leftEdgeConstraint?.isActive = true
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12).isActive = true
                leftEdgeLabel = label
            }
            if rightEdgeLabel == nil {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                addSubview(label)
                rightEdgeConstraint = label.topAnchor.constraint(equalTo: bottomAnchor, constant: -edgeLabelTopPadding)
                rightEdgeConstraint?.isActive = true
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32).isActive = true
                rightEdgeLabel = label
            }
            applyEdgeLabelStyle()
            let barLine = chart as? BarLineChartViewBase
            if barLine != nil {
                updateEdgeLabels(left: barLine!.lowestVisibleX, right: barLine!.highestVisibleX)
            }
            
            if let bar = self as? RNBarLineChartViewBase { bar.applyExtraOffsets() }
        } else {
            leftEdgeLabel?.removeFromSuperview()
            rightEdgeLabel?.removeFromSuperview()
            leftEdgeLabel = nil
            rightEdgeLabel = nil
            leftEdgeConstraint = nil
            rightEdgeConstraint = nil
            if let bar = self as? RNBarLineChartViewBase { bar.applyExtraOffsets() }
        }
    }

    private func applyEdgeLabelStyle() {
        guard let barLine = chart as? BarLineChartViewBase else { return }
        let axis = barLine.xAxis
        let font = axis.labelFont
        let color = axis.labelTextColor
        leftEdgeLabel?.font = font
        rightEdgeLabel?.font = font
        leftEdgeLabel?.textColor = color
        rightEdgeLabel?.textColor = color
        leftEdgeLabel?.textAlignment = .center
        rightEdgeLabel?.textAlignment = .center
        leftEdgeLabel?.numberOfLines = 0
        rightEdgeLabel?.numberOfLines = 0
        leftEdgeLabel?.lineBreakMode = .byWordWrapping
        rightEdgeLabel?.lineBreakMode = .byWordWrapping
        
        // Ensure new text has updated intrinsic size before computing height
        layoutIfNeeded()
        let height = edgeLabelHeight()
        if height > 0 {
            leftEdgeConstraint?.constant = -height
            rightEdgeConstraint?.constant = -height
        } else {
            leftEdgeConstraint?.constant = -(font.lineHeight)
            rightEdgeConstraint?.constant = -(font.lineHeight)
        }
    }

    func edgeLabelHeight() -> CGFloat {
        let leftHeight = leftEdgeLabel?.intrinsicContentSize.height ?? 0
        let rightHeight = rightEdgeLabel?.intrinsicContentSize.height ?? 0
        return max(leftHeight, rightHeight)
    }

    private func updateEdgeLabels(left: Double, right: Double) {
        guard edgeLabelEnabled, let barLine = chart as? BarLineChartViewBase else { return }
        
        // 1. 상한 계산
        let axisMaxIdx = Int(barLine.xAxis.axisMaximum) - 1          // ← 핵심
        let formatter  = barLine.xAxis.valueFormatter
        let labelMax   = (formatter as? IndexAxisValueFormatter)
                         .map { $0.values.count - 1 } ?? axisMaxIdx
        let safeMaxIdx = min(axisMaxIdx, labelMax)

        // 2. 인덱스 보정
        let leftIdx  = max(Int(ceil(left)), 0)
        let rightIdx = min(Int(floor(right)), safeMaxIdx)

        // 3. 라벨 표시
        leftEdgeLabel?.isHidden  = false
        rightEdgeLabel?.isHidden = rightIdx <= leftIdx

        if let v = formatter?.stringForValue(Double(leftIdx), axis: barLine.xAxis) {
            leftEdgeLabel?.text = v
            leftEdgeLabelHasNewline = v.contains("\n")
        }

        if !rightEdgeLabel!.isHidden,
           let v = formatter?.stringForValue(Double(rightIdx), axis: barLine.xAxis) {
            rightEdgeLabel?.text = v
            rightEdgeLabelHasNewline = v.contains("\n")
        }

        applyEdgeLabelStyle()
        layoutIfNeeded()
        (self as? RNBarLineChartViewBase)?.applyExtraOffsets()
    }

    func sendEvent(_ action:String) {
        var dict = [AnyHashable: Any]()

        dict["action"] = action
        if chart is BarLineChartViewBase {
            let viewPortHandler = chart.viewPortHandler
            let barLineChart = chart as! BarLineChartViewBase

            dict["scaleX"] = barLineChart.scaleX
            dict["scaleY"] = barLineChart.scaleY

            if viewPortHandler != nil {
                let handler = viewPortHandler
                let center = barLineChart.valueForTouchPoint(point: handler.contentCenter, axis: YAxis.AxisDependency.left)
                dict["centerX"] = center.x
                dict["centerY"] = center.y

                let leftBottom = barLineChart.valueForTouchPoint(point: CGPoint(x: handler.contentLeft, y: handler.contentBottom), axis: YAxis.AxisDependency.left)
                let rightTop = barLineChart.valueForTouchPoint(point: CGPoint(x: handler.contentRight, y: handler.contentTop), axis: YAxis.AxisDependency.left)

                let minX = barLineChart.chartXMin
                let maxX = barLineChart.chartXMax
                // let dragOffset = handler.dragOffsetX

                let spaceMin = barLineChart.xAxis.spaceMin
                let spaceMax = barLineChart.xAxis.spaceMax
                
                let allowedMin = minX - spaceMin
                let allowedMax = maxX + spaceMax

                let originalWidth = rightTop.x - leftBottom.x
                var leftValue = leftBottom.x
                var rightValue = rightTop.x

                if leftValue < allowedMin {
                    leftValue = allowedMin
                    rightValue = leftValue + originalWidth
                }

                if rightValue > allowedMax {
                    rightValue = allowedMax
                    leftValue = rightValue - originalWidth
                }

                if leftValue < allowedMin { leftValue = allowedMin }
                if rightValue > allowedMax { rightValue = allowedMax }

                if leftValue < 0 {
                    leftValue = 0
                }
                
                dict["left"] = leftValue
                dict["bottom"] = leftBottom.y
                dict["right"] = rightValue
                dict["top"] = rightTop.y

                updateEdgeLabels(left: leftValue, right: rightValue)

                if self.group != nil && self.identifier != nil {
                    ChartGroupHolder.sync(group: self.group!, identifier: self.identifier!, scaleX: barLineChart.scaleX, scaleY: barLineChart.scaleY, centerX: center.x, centerY: center.y, performImmediately: true)
                }
            }
        }

        if let callback = self.onChange {
            callback(dict)
        }
    }

    func setGroup(_ group: String) {
        self.group = group
    }

    func setIdentifier(_ identifier: String) {
        self.identifier = identifier
    }

    func setSyncX(_ syncX: Bool) {
        self.syncX = syncX
    }

    func setSyncY(_ syncY: Bool) {
        self.syncY = syncY
    }

    func onAfterDataSetChanged() {
    }

    override open func didSetProps(_ changedProps: [String]!) {
        super.didSetProps(changedProps)
        // chart.notifyDataSetChanged()
        onAfterDataSetChanged()
        // chart.setNeedsLayout()
        // chart.layoutIfNeeded()

        if hasSentLoadComplete {
            if changedProps.contains("data") || changedProps.contains("xAxis") || changedProps.contains("yAxis") || changedProps.contains("valueFormatter") {
                DispatchQueue.main.async { [weak self] in
                    self?.sendEvent("chartLoadComplete")
                }
            }
        } else if bounds.width > 0 && bounds.height > 0 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.sendEvent("chartLoadComplete")
                self.hasSentLoadComplete = true
            }
        }

        if self.group != nil && self.identifier != nil && chart is BarLineChartViewBase {
            ChartGroupHolder.addChart(group: self.group!, identifier: self.identifier!, chart: chart as! BarLineChartViewBase, syncX: syncX, syncY: syncY);
        }

    }

}
