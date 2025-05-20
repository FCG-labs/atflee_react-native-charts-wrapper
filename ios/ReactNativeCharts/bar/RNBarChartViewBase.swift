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

        if let horizontalChart = chart as? HorizontalBarChartView {
            horizontalChart.renderer = RoundedHorizontalBarChartRenderer(dataProvider: horizontalChart, animator: horizontalChart.chartAnimator, viewPortHandler: horizontalChart.viewPortHandler, radius: barRadius)
            horizontalChart.setNeedsDisplay()
        } else if let verticalChart = chart as? BarChartView {
            verticalChart.renderer = RoundedBarChartRenderer(dataProvider: verticalChart, animator: verticalChart.chartAnimator, viewPortHandler: verticalChart.viewPortHandler, radius: barRadius)
            verticalChart.setNeedsDisplay()
        }
    }
}
