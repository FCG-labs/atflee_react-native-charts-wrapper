import Foundation
import DGCharts

open class RoundedHorizontalBarChartRenderer: HorizontalBarChartRenderer {
    @objc open var radius: CGFloat

    public init(dataProvider: BarChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler, radius: CGFloat) {
        self.radius = radius
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }

    open override func drawDataSet(context: CGContext, dataSet: IBarChartDataSet, index: Int) {
        guard let dataProvider = dataProvider else { return }
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        var buffer = _buffers[index]

        context.saveGState()

        for j in stride(from: 0, to: Int(buffer.count), by: 4) {
            var barRect = CGRect(x: CGFloat(buffer[j]), y: CGFloat(buffer[j + 1]), width: CGFloat(buffer[j + 2] - buffer[j]), height: CGFloat(buffer[j + 3] - buffer[j + 1]))
            trans.rectValueToPixel(&barRect)

            if !viewPortHandler.isInBoundsLeft(barRect.maxY) { continue }
            if !viewPortHandler.isInBoundsRight(barRect.minY) { break }

            let color = dataSet.color(atIndex: j / 4)
            context.setFillColor(color.cgColor)

            let path = UIBezierPath(roundedRect: barRect, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: CGSize(width: radius, height: radius))
            context.addPath(path.cgPath)
            context.fillPath()
        }

        context.restoreGState()
    }
}
