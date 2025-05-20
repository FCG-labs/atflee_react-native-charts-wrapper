import Foundation
import DGCharts

class RoundedCombinedChartRenderer: DataRenderer {
    private weak var chart: CombinedChartView?
    private var renderers: [DataRenderer] = []
    private var roundedBarRenderer: RoundedBarChartRenderer?
    var barRadius: CGFloat

    init(chart: CombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler, barRadius: CGFloat) {
        self.chart = chart
        self.barRadius = barRadius
        super.init(animator: animator, viewPortHandler: viewPortHandler)
        configureRenderers()
    }

    private func configureRenderers() {
        renderers.removeAll()
        roundedBarRenderer = nil

        guard let chart = chart else { return }

        for rawValue in chart.drawOrder {
            guard let order = CombinedChartView.DrawOrder(rawValue: rawValue) else { continue }
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
        configureRenderers()
    }

    override func drawData(context: CGContext) {
        for renderer in renderers {
            renderer.drawData(context: context)
        }
    }

    override func drawValues(context: CGContext) {
        for renderer in renderers {
            renderer.drawValues(context: context)
        }
    }

    override func drawExtras(context: CGContext) {
        for renderer in renderers {
            renderer.drawExtras(context: context)
        }
    }

    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        for renderer in renderers {
            renderer.drawHighlighted(context: context, indices: indices)
        }
    }
}
