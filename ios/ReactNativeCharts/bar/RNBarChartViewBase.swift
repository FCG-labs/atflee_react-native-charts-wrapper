//  Created by xudong wu on 24/02/2017.
//  Copyright wuxudong
//

import DGCharts
import SwiftyJSON

class RNBarChartViewBase: RNBarLineChartViewBase {

    fileprivate var barChart: BarChartView {
        get {
            return chart as! BarChartView
        }
    }

    private var barRadius: CGFloat = 0

    func setDrawValueAboveBar(_ enabled: Bool) {
        barChart.drawValueAboveBarEnabled = enabled
    }

    func setDrawBarShadow(_ enabled: Bool) {
        barChart.drawBarShadowEnabled = enabled
    }
    
    func setHighlightFullBarEnabled(_ enabled: Bool) {
        barChart.highlightFullBarEnabled = enabled
    }

    func setBarRadius(_ radius: NSNumber) {
        barRadius = CGFloat(truncating: radius)

        if let horizontal = chart as? HorizontalBarChartView {
            if barRadius > 0 {
                if let renderer = horizontal.renderer as? RoundedHorizontalBarChartRenderer {
                    renderer.setRadius(barRadius)
                } else {
                    horizontal.renderer = RoundedHorizontalBarChartRenderer(dataProvider: horizontal, animator: horizontal.chartAnimator, viewPortHandler: horizontal.viewPortHandler, radius: barRadius)
                }
            } else {
                if !(horizontal.renderer is HorizontalBarChartRenderer) {
                    horizontal.renderer = HorizontalBarChartRenderer(dataProvider: horizontal, animator: horizontal.chartAnimator, viewPortHandler: horizontal.viewPortHandler)
                }
            }
            horizontal.setNeedsDisplay()
        } else if let vertical = chart as? BarChartView {
            if barRadius > 0 {
                if let renderer = vertical.renderer as? RoundedBarChartRenderer {
                    renderer.setRadius(barRadius)
                } else {
                    vertical.renderer = RoundedBarChartRenderer(dataProvider: vertical, animator: vertical.chartAnimator, viewPortHandler: vertical.viewPortHandler, radius: barRadius)
                }
            } else {
                if !(vertical.renderer is BarChartRenderer) {
                    vertical.renderer = BarChartRenderer(dataProvider: vertical, animator: vertical.chartAnimator, viewPortHandler: vertical.viewPortHandler)
                }
            }
            vertical.setNeedsDisplay()
        }
    }

    // Auto-fit bars so that edge bars are fully visible (replaces JS axisMaximum hack)
    override func setData(_ data: NSDictionary) {
        super.setData(data)
        barChart.fitBars = true
    }
}
