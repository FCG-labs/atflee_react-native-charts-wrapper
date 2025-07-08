import Foundation
import DGCharts

class RoundedBarChartRenderer: BarChartRenderer {
    var radius: CGFloat
    private let verticalToTop: Bool  = false     // true: ⬆︎→marker, false: marker→⬇︎
    private let markerPadDp: CGFloat = 10.0      // 라인·마커 여백

    init(dataProvider: BarChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler, radius: CGFloat) {

        self.radius = radius
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }

    func setRadius(_ radius: CGFloat) {
        self.radius = radius
    }

    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        // 0) 바 사각형 하이라이트가 필요하면 유지
        super.drawHighlighted(context: context, indices: indices)

        guard
            let provider   = dataProvider,
            let chartBase  = provider as? BarLineChartViewBase
        else { return }

        for hi in indices {
            guard
                let set = provider.barData?
                        .dataSets[hi.dataSetIndex] as? BarChartDataSetProtocol,
                set.isHighlightEnabled
            else { continue }

            // 1) 데이터점 → 픽셀 (막대 상단)
            let trans = provider.getTransformer(forAxis: set.axisDependency)
            let pt    = trans.pixelForValues(x: hi.x, y: hi.y)

            // 2) 마커 Y(패드 포함)
            var markerY = pt.y
            if chartBase.drawMarkers, let marker = chartBase.marker {
                let off   = marker.offsetForDrawing(atPoint: CGPoint(x: pt.x, y: pt.y))
                let pad   = markerPadDp                
                markerY   = pt.y + off.y + pad         // off.y: 음수 → 위로
            }
            if markerY < viewPortHandler.contentTop {   // 위로 튀는 것 방지
                markerY = viewPortHandler.contentTop
            }

            // 3) 마커 렌더용 좌표 기록(필수)
            hi.setDraw(x: pt.x, y: pt.y)

            // 4) 펜 설정
            context.saveGState()
            context.setStrokeColor(set.highlightColor.cgColor)
            context.setLineWidth(max(set.highlightLineWidth, 1))
            if let dash = set.highlightLineDashLengths {
                context.setLineDash(phase: 0, lengths: dash)
            }
            // context.setAlpha(CGFloat(set.highlightAlpha) / 255.0)

            // 5) 수직선 (절반)
            let (yStart, yEnd) = verticalToTop
                ? (viewPortHandler.contentTop, markerY)
                : (markerY, viewPortHandler.contentBottom)
            context.move(to: CGPoint(x: pt.x, y: yStart))
            context.addLine(to: CGPoint(x: pt.x, y: yEnd))

            // 6) 수평선 (마커 Y)
//            context.move(to: CGPoint(x: viewPortHandler.contentLeft,  y: markerY))
//            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: markerY))

            context.strokePath()
            context.restoreGState()
        }
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
            // Positive values round the top corners, negatives round the bottom
            let corners: UIRectCorner = isPositive ? [.topLeft, .topRight] : [.bottomLeft, .bottomRight]

            let left = x - barWidthHalf
            let right = x + barWidthHalf
            let top = isPositive ? y : 0.0
            let bottom = isPositive ? 0.0 : y

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

    // MARK: - Value Labels (no-clip override)
    override func drawValues(context: CGContext) {
        guard
            let dataProvider = dataProvider,
            let barData      = dataProvider.barData,
            isDrawingValuesAllowed(dataProvider: dataProvider)
        else { return }

        let phaseY           = animator.phaseY
        let dataSets         = barData.dataSets
        let valueOffsetPlus: CGFloat = 4.5

        for dataSetIndex in 0..<dataSets.count {
            guard
                let dataSet = dataSets[dataSetIndex] as? BarChartDataSetProtocol,
                dataSet.isVisible && (dataSet.isDrawValuesEnabled || dataSet.isDrawIconsEnabled)
            else { continue }

            let drawValueAboveBar = dataProvider.isDrawValueAboveBarEnabled
            let valueFont         = dataSet.valueFont
            let trans             = dataProvider.getTransformer(forAxis: dataSet.axisDependency)

            // Offsets for positive / negative bars
            let posOffset = drawValueAboveBar
                ? valueOffsetPlus
                : -(valueFont.lineHeight + valueOffsetPlus)
            let negOffset = drawValueAboveBar
                ? -(valueFont.lineHeight + valueOffsetPlus)
                : valueOffsetPlus

            // Entry count adjusted for animation phase
            let entryCount = Int(min(ceil(Double(dataSet.entryCount) * animator.phaseX), Double(dataSet.entryCount)))
            for j in 0..<entryCount {
                guard let e = dataSet.entryForIndex(j) as? BarChartDataEntry else { continue }

                // Prepare value text & colour
                let valueTextColour = dataSet.valueTextColorAt(j)
                let valueText       = dataSet.valueFormatter.stringForValue(e.y,
                                                                            entry: e,
                                                                            dataSetIndex: dataSetIndex,
                                                                            viewPortHandler: viewPortHandler)

                // Map value position to pixel
                var pt = trans.pixelForValues(x: e.x, y: e.y * phaseY)
                pt.y += (e.y >= 0.0 ? posOffset : negOffset)

                // Cull if completely out of bounds (x only, y can overflow)
                if !viewPortHandler.isInBoundsRight(pt.x) { break }
                if !viewPortHandler.isInBoundsLeft(pt.x)  { continue }

                if dataSet.isDrawValuesEnabled {
                    context.drawText(valueText,
                                     at: pt,
                                     align: .center,
                                     attributes: [
                                        .font: valueFont,
                                        .foregroundColor: valueTextColour
                                     ])
                }
            }
        }
    }
}
