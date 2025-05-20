import Foundation
import DGCharts

class RoundedCombinedChartRenderer: CombinedChartRenderer {
    var barRadius: CGFloat
    private var roundedBarRenderer: RoundedBarChartRenderer?

    init(chart: CombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler, barRadius: CGFloat) {
        self.barRadius = barRadius
        super.init(chart: chart, animator: animator, viewPortHandler: viewPortHandler)
        configureRenderers(for: chart)
    }

    private func configureRenderers(for chart: CombinedChartView) {
        renderers.removeAll()
        roundedBarRenderer = nil

        for order in chart.drawOrder {
            switch order {
            case .bar:
                if chart.barData != nil {
                    let renderer = RoundedBarChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler, radius: barRadius)
                    roundedBarRenderer = renderer
                    renderers.append(renderer)
                }
            case .bubble:
                if chart.bubbleData != nil {
                    renderers.append(BubbleChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            case .line:
                if chart.lineData != nil {
                    renderers.append(LineChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            case .candle:
                if chart.candleData != nil {
                    renderers.append(CandleStickChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            case .scatter:
                if chart.scatterData != nil {
                    renderers.append(ScatterChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            }
        }
    }

    func setRadius(_ radius: CGFloat) {
        barRadius = radius
        if let renderer = roundedBarRenderer {
            renderer.setRadius(radius)
        } else if let chart = chart as? CombinedChartView, radius > 0 {
            configureRenderers(for: chart)
        }
    }
}
