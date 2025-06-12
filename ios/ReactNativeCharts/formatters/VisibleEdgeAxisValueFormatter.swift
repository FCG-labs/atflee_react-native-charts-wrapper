import Foundation
import DGCharts

@objc(VisibleEdgeAxisValueFormatter)
open class VisibleEdgeAxisValueFormatter: NSObject, ValueFormatter, AxisValueFormatter {
    weak var chart: BarLineChartViewBase?
    var base: AxisValueFormatter
    @objc public var enabled: Bool = true

    @objc public init(chart: BarLineChartViewBase, base: AxisValueFormatter, enabled: Bool = true) {
        self.chart = chart
        self.base = base
        self.enabled = enabled
    }

    open func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard enabled, let chart = chart else {
            return base.stringForValue(value, axis: axis)
        }
        let lowest = chart.lowestVisibleX
        let highest = chart.highestVisibleX

        // fall back to the base when no range is computed yet
        if lowest == highest {
            return base.stringForValue(value, axis: axis)
        }

        let leftIndex = Int(floor(lowest))
        let rightIndex = Int(ceil(highest))

        let index = Int(value.rounded())
        if index == leftIndex || index == rightIndex {
            return base.stringForValue(value, axis: axis)
        }
        return ""
    }

    open func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        return stringForValue(entry.x, axis: nil)
    }
}
