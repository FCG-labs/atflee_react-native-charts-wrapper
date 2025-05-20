import Foundation
import DGCharts

class RoundedCombinedChartRenderer: CombinedChartRenderer {
    private var customRenderers: [DataRenderer] = []
    private var roundedBarRenderer: RoundedBarChartRenderer?
    var barRadius: CGFloat

    init(chart: CombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler, barRadius: CGFloat) {
        self.barRadius = barRadius
        super.init(chart: chart, animator: animator, viewPortHandler: viewPortHandler)
        configureRenderers()
    }

    private func configureRenderers() {
        customRenderers.removeAll()
        roundedBarRenderer = nil

        guard let chart = chart as? CombinedChartView else { return }

        for rawValue in chart.drawOrder {
            guard let order = CombinedChartView.DrawOrder(rawValue: rawValue) else { continue }
            switch order {
            case .bar:
                if chart.barData != nil {
                    let renderer = RoundedBarChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler, radius: barRadius)
                    roundedBarRenderer = renderer
                    customRenderers.append(renderer)
                }
            case .bubble:
                if chart.bubbleData != nil {
                    customRenderers.append(BubbleChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            case .line:
                if chart.lineData != nil {
                    customRenderers.append(LineChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            case .candle:
                if chart.candleData != nil {
                    customRenderers.append(CandleStickChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            case .scatter:
                if chart.scatterData != nil {
                    customRenderers.append(ScatterChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                }
            }
        }
    }

    func setRadius(_ radius: CGFloat) {
        barRadius = radius
        if let barRenderer = roundedBarRenderer {
            barRenderer.setRadius(radius)
        } else {
            configureRenderers()
        }
    }

    override func drawData(context: CGContext) {
        for renderer in customRenderers {
            renderer.drawData(context: context)
        }
    }

    override func drawValues(context: CGContext) {
        for renderer in customRenderers {
            renderer.drawValues(context: context)
        }
    }

    override func drawExtras(context: CGContext) {
        for renderer in customRenderers {
            renderer.drawExtras(context: context)
        }
    }

    override func initBuffers() {
        for renderer in customRenderers {
            renderer.initBuffers()
        }
    }
}
