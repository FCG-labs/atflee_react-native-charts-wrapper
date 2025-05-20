import Foundation
import DGCharts

class RoundedCombinedChartRenderer: CombinedChartRenderer {
    var barRadius: CGFloat

    init(chart: CombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler, barRadius: CGFloat) {
        self.barRadius = barRadius
        super.init(chart: chart, animator: animator, viewPortHandler: viewPortHandler)
        self.barChartRenderer = RoundedBarChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler, radius: barRadius)
    }

    override func createRenderers() {
        super.createRenderers()
        self.barChartRenderer = RoundedBarChartRenderer(dataProvider: chart as! CombinedChartView, animator: animator, viewPortHandler: viewPortHandler, radius: barRadius)
    }

    func setRadius(_ radius: CGFloat) {
        barRadius = radius
        if let renderer = barChartRenderer as? RoundedBarChartRenderer {
            renderer.setRadius(radius)
        } else if let chart = chart as? CombinedChartView {
            barChartRenderer = RoundedBarChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler, radius: radius)
        }
    }
}
