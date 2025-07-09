import Foundation
import DGCharts

class RoundedCombinedChartRenderer: CombinedChartRenderer {
    private var customRenderers: [DataRenderer] = []
    private var roundedBarRenderer: RoundedBarChartRenderer?
    var barRadius: CGFloat

    init(chart: CombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler, barRadius: CGFloat) {
        self.barRadius = barRadius
        super.init(chart: chart, animator: animator, viewPortHandler: viewPortHandler)
        createRenderers()
    }

    func createRenderers() {
        customRenderers.removeAll()
        roundedBarRenderer = nil

        guard let chart = chart as? CombinedChartView else {
            return
        }
        for order in chart.drawOrder {
            guard let drawOrder = CombinedChartView.DrawOrder(rawValue: order) else {
                continue
            }
            
            switch drawOrder {
            case .bar:
                if chart.barData != nil {
                    let renderer = RoundedBarChartRenderer(
                        dataProvider: chart,
                        animator: animator,
                        viewPortHandler: viewPortHandler,
                        radius: barRadius
                    )
                    roundedBarRenderer = renderer
                    customRenderers.append(renderer)
                }
            case .bubble:
                if chart.bubbleData != nil {
                    customRenderers.append(
                        BubbleChartRenderer(
                            dataProvider: chart,
                            animator: animator,
                            viewPortHandler: viewPortHandler
                        )
                    )
                }
            case .line:
                customRenderers.append(
                    NoClipLineChartRenderer(
                        dataProvider: chart,
                        animator: animator,
                        viewPortHandler: viewPortHandler
                    )
                )
            case .candle:
                if chart.candleData != nil {
                    customRenderers.append(
                        CandleStickChartRenderer(
                            dataProvider: chart,
                            animator: animator,
                            viewPortHandler: viewPortHandler
                        )
                    )
                }
            case .scatter:
                if chart.scatterData != nil {
                    customRenderers.append(
                        ScatterChartRenderer(
                            dataProvider: chart,
                            animator: animator,
                            viewPortHandler: viewPortHandler
                        )
                    )
                }
            }
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

    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        for renderer in customRenderers {
            renderer.drawHighlighted(context: context, indices: indices)
        }
    }

    override func initBuffers() {
        for renderer in customRenderers {
            renderer.initBuffers()
        }
    }

    func setRadius(_ radius: CGFloat) {
        barRadius = radius
        createRenderers()
    }
}
