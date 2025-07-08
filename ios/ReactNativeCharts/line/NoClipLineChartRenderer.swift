import Foundation
import DGCharts
import CoreGraphics

/// Custom LineChart renderer that bypasses clipping and ensures value labels
/// remain visible even when entries sit on the chart's upper edge.
///
/// Strategy:
/// 1. Do NOT apply any clipping to the CGContext (default `LineChartRenderer` already
///    avoids clipping, but the chart view may clip.  Since this renderer is invoked
///    outside the `clipValuesToContentEnabled` guard, labels can spill over if
///    additional space exists).
/// 2. If there is not enough space above a point (i.e. label would render above
///    `contentTop`), draw the label *below* the point instead. This guarantees the
///    label remains inside the visible viewport for values equal to `axisMaximum`.
open class NoClipLineChartRenderer: LineChartRenderer {
    /// Same initializer signature as the superclass.
    @objc public override init(dataProvider: LineChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler) {
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }

    open override func drawValues(context: CGContext) {
        // Disable any clipping region so that value-labels can render outside contentRect if needed.
        context.saveGState()
        context.resetClip()
        guard
            let dataProvider = dataProvider,
            let lineData     = dataProvider.lineData,
            isDrawingValuesAllowed(dataProvider: dataProvider)
        else { return }

        let phaseY = animator.phaseY
        var pt     = CGPoint()

        // DEBUG: begin drawing datasets
        print("[NoClipLineChartRenderer] drawValues – lineDataSets: \(lineData.dataSetCount)")
        for i in lineData.indices {
            guard
                let dataSet = lineData[i] as? LineChartDataSetProtocol,
                dataSet.isVisible && (dataSet.isDrawValuesEnabled || dataSet.isDrawIconsEnabled)
            else { continue }

            let valueFont    = dataSet.valueFont
            let formatter    = dataSet.valueFormatter
            let angleRadians = dataSet.valueLabelAngle * .pi / 180.0
            let trans        = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
            let valueMatrix  = trans.valueToPixelMatrix
            let iconsOffset  = dataSet.iconsOffset
            // Base vertical offset (mirrors logic in stock renderer)
            var valOffset    = Int(dataSet.circleRadius * 1.75)
            if !dataSet.isDrawCirclesEnabled {
                valOffset = valOffset / 2
            }

            let lowestVisibleX  = dataProvider.lowestVisibleX
            let highestVisibleX = dataProvider.highestVisibleX

            for j in 0 ..< dataSet.entryCount {
                guard let e = dataSet.entryForIndex(j) else { continue }

                // Skip entries outside current visible range
                if e.x < lowestVisibleX || e.x > highestVisibleX { continue }

                // Translate entry position to pixels
                pt.x = CGFloat(e.x)
                pt.y = CGFloat(e.y * phaseY)
                pt    = pt.applying(valueMatrix)

                // Abort early when past right bound; continue when outside left/top/bottom
                if !viewPortHandler.isInBoundsRight(pt.x) { break }
                // Allow Y coordinates to overflow so labels for max/min values
                // can still be drawn inside the viewport. Mirror the default
                // bar chart renderer which only checks X bounds here.
                if !viewPortHandler.isInBoundsLeft(pt.x) { continue }

                // Calculate text metrics once for smarter placement
                let valueText = formatter.stringForValue(e.y,
                                                         entry: e,
                                                         dataSetIndex: i,
                                                         viewPortHandler: viewPortHandler)
                let textHeight = valueFont.lineHeight
                let textWidth  = valueText.size(withAttributes: [.font: valueFont]).width
                let offsetY    = CGFloat(valOffset)
                var drawPoint  = pt

                let chartTop = viewPortHandler.contentTop
                let aboveY   = pt.y - offsetY - textHeight

                // ALWAYS draw above. If 공간 부족, 클램프해서 contentTop 안으로만 유지
                drawPoint.y = max(aboveY, chartTop)

                // 좌·우 경계 안쪽으로만 조정해 잘림 방지
                let halfW = textWidth / 2.0
                if drawPoint.x - halfW < viewPortHandler.contentLeft {
                    drawPoint.x = viewPortHandler.contentLeft + halfW
                }
                if drawPoint.x + halfW > viewPortHandler.contentRight {
                    drawPoint.x = viewPortHandler.contentRight - halfW
                }

                // DEBUG: log first 3 entries of each dataset
                if j < 3 {
                    print("[NoClipLineChartRenderer] dsIdx:\(i) entryIdx:\(j) y:\(e.y) aboveY:\(aboveY) finalY:\(drawPoint.y) contentTop:\(chartTop)")
                }

                // Finally draw the text
                if dataSet.isDrawValuesEnabled {
                    context.drawText(valueText,
                                     at: drawPoint,
                                     align: .center,
                                     angleRadians: angleRadians,
                                     attributes: [
                                        .font: valueFont,
                                        .foregroundColor: dataSet.valueTextColorAt(j)
                                     ])
                }

                if dataSet.isDrawValuesEnabled {
                    let valueText = formatter.stringForValue(e.y,
                                                             entry: e,
                                                             dataSetIndex: i,
                                                             viewPortHandler: viewPortHandler)
                    context.drawText(valueText,
                                     at: drawPoint,
                                     align: .center,
                                     angleRadians: angleRadians,
                                     attributes: [
                                        .font: valueFont,
                                        .foregroundColor: dataSet.valueTextColorAt(j)
                                     ])
                }

                // Icons (if any) follow default renderer semantics
                if let icon = e.icon, dataSet.isDrawIconsEnabled {
                    context.drawImage(icon,
                                      atCenter: CGPoint(x: pt.x + iconsOffset.x, y: pt.y + iconsOffset.y),
                                      size: icon.size)
                }
            }
        }
        context.restoreGState()
    }
}
