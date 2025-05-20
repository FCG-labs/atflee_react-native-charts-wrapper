import Foundation
import DGCharts

class RoundedBarChartRenderer: BarChartRenderer {
    var radius: CGFloat

    init(dataProvider: BarChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler, radius: CGFloat) {

        self.radius = radius
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }

    func setRadius(_ radius: CGFloat) {
        self.radius = radius
    }

    override func drawDataSet(context: CGContext, dataSet: BarChartDataSetProtocol, index: Int) {
        guard let dataProvider = dataProvider else { return }

        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        let barData = dataProvider.barData
        let barWidth = barData?.barWidth ?? 0
        let phaseY = animator.phaseY
        let phaseX = animator.phaseX
        let barWidthHalf = barWidth / 2.0
        var barRect = CGRect()

        let count = Int(ceil(Double(dataSet.entryCount) * phaseX))
        for i in 0 ..< count {
            guard let e = dataSet.entryForIndex(i) as? BarChartDataEntry else { continue }
            let x = e.x
            let y = e.y
            let isPositive = y >= 0
            // Use the sign of the entry to decide which corners to round
            let corners: UIRectCorner = isPositive ? [.topLeft, .topRight] : [.bottomLeft, .bottomRight]

            let left = x - barWidthHalf
            let right = x + barWidthHalf
            var top = y >= 0.0 ? y : 0.0
            var bottom = y <= 0.0 ? y : 0.0

            if top < bottom {
                swap(&top, &bottom)
            }

            barRect.origin.x = CGFloat(left)
            barRect.origin.y = CGFloat(bottom) * CGFloat(phaseY)
            barRect.size.width = CGFloat(right - left)
            barRect.size.height = CGFloat(top - bottom) * CGFloat(phaseY)

            trans.rectValueToPixel(&barRect)

            if !viewPortHandler.isInBoundsLeft(barRect.maxX) {
                continue
            }
            if !viewPortHandler.isInBoundsRight(barRect.minX) {
                break
            }

            context.setFillColor(dataSet.color(atIndex: i).cgColor)
            let path = UIBezierPath(
                roundedRect: barRect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            context.addPath(path.cgPath)
            context.fillPath()
        }
    }
}
