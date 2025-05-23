import Foundation
import DGCharts

class RoundedHorizontalBarChartRenderer: HorizontalBarChartRenderer {
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
            // Determine if the bar represents a positive or negative value
            let isPositive = y >= 0
            // Positive bars extend to the right, negative bars to the left
            let corners: UIRectCorner = isPositive ? [.topRight, .bottomRight] : [.topLeft, .bottomLeft]

            let left = isPositive ? 0.0 : y
            let right = isPositive ? y : 0.0

            barRect.origin.y = CGFloat(x - barWidthHalf)
            barRect.size.height = CGFloat(barWidth)
            barRect.origin.x = CGFloat(left) * CGFloat(phaseY)
            barRect.size.width = CGFloat(right - left) * CGFloat(phaseY)

            trans.rectValueToPixel(&barRect)

            if !viewPortHandler.isInBoundsTop(barRect.maxY) {
                continue
            }
            if !viewPortHandler.isInBoundsBottom(barRect.minY) {
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
