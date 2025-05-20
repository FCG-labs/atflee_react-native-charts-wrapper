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
        let value = CGFloat(truncating: radius)
        if let horizontal = chart as? HorizontalBarChartView {
            if let renderer = horizontal.renderer as? RoundedHorizontalBarChartRenderer {
                renderer.setRadius(value)
            } else {
                horizontal.renderer = RoundedHorizontalBarChartRenderer(dataProvider: horizontal, animator: horizontal.chartAnimator, viewPortHandler: horizontal.viewPortHandler, radius: value)
            }
            horizontal.setNeedsDisplay()
        } else if let vertical = chart as? BarChartView {
            if let renderer = vertical.renderer as? RoundedBarChartRenderer {
                renderer.setRadius(value)
            } else {
                vertical.renderer = RoundedBarChartRenderer(dataProvider: vertical, animator: vertical.chartAnimator, viewPortHandler: vertical.viewPortHandler, radius: value)
            }
            vertical.setNeedsDisplay()
        }
    }
}
