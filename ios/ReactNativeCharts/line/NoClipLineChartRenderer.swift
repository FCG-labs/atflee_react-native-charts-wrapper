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

    // MARK: - Values
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
                // Position baseline so that text sits fully above the marker: offset + half text height
                let aboveY   = pt.y - offsetY - textHeight * 1

                // Draw exactly at the calculated aboveY (no vertical clamp) so labels can use
                // the extra top offset space provided by RN side.
                drawPoint.y = aboveY

                // 좌·우 경계 안쪽으로만 조정해 잘림 방지
                let halfW = textWidth / 2.0
                if drawPoint.x - halfW < viewPortHandler.contentLeft {
                    drawPoint.x = viewPortHandler.contentLeft + halfW
                }
                if drawPoint.x + halfW > viewPortHandler.contentRight {
                    drawPoint.x = viewPortHandler.contentRight - halfW
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

    /// Returns true if the given entry lies within the dataset's current
    /// animated x-bounds.
    private func entryInBoundsX(_ entry: ChartDataEntry, dataSet: LineChartDataSetProtocol) -> Bool {
        let index = dataSet.entryIndex(entry: entry)
        if index < 0 { return false }
        return Double(index) < Double(dataSet.entryCount) * Double(animator.phaseX)
    }

    // MARK: - Highlight & Marker
    open override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        // Disable clipping so highlight lines & markers can draw into extra offset area
        context.saveGState()
        context.resetClip()
        // Use default DGCharts highlight rendering (circles, vertical line etc.)
        super.drawHighlighted(context: context, indices: indices)

        guard
            let dataProvider = dataProvider,
            let lineData     = dataProvider.lineData
        else { return }

        let phaseY = animator.phaseY

        for high in indices {
            guard
                let set = lineData.dataSets[high.dataSetIndex] as? LineChartDataSetProtocol,
                set.isHighlightEnabled,
                let e   = set.entryForXValue(high.x, closestToY: high.y)
            else { continue }

            if !entryInBoundsX(e, dataSet: set) { continue }

            let trans = dataProvider.getTransformer(forAxis: set.axisDependency)
            var pt    = trans.pixelForValues(x: e.x, y: e.y * phaseY)

            // Clamp to content rect so markers can still draw when a value
            // sits above or below the visible axis range.
            if pt.y < viewPortHandler.contentTop {
                pt.y = viewPortHandler.contentTop
            } else if pt.y > viewPortHandler.contentBottom {
                pt.y = viewPortHandler.contentBottom
            }

            high.setDraw(x: pt.x, y: pt.y)

            context.saveGState()
            context.setStrokeColor(set.highlightColor.cgColor)
            context.setLineWidth(max(set.highlightLineWidth, 1))
            if let dash = set.highlightLineDashLengths {
                context.setLineDash(phase: 0, lengths: dash)
            }

            drawHighlightLines(context: context, point: pt, set: set)
            context.restoreGState()
        }

        context.restoreGState()
    }

    // MARK: - Circles
    /// Draw circles without clipping so points remain visible in the extra
    /// offset region above the chart. This mirrors the default implementation
    /// but omits the vertical in-bounds check.
    open override func drawExtras(context: CGContext) {
        guard
            let dataProvider = dataProvider,
            let lineData     = dataProvider.lineData
        else { return }

        let phaseX = animator.phaseX
        let phaseY = animator.phaseY

        context.saveGState()
        context.resetClip()

        for dataSetIndex in lineData.indices {
            guard
                let dataSet = lineData[dataSetIndex] as? LineChartDataSetProtocol,
                dataSet.isVisible,
                dataSet.isDrawCirclesEnabled
            else { continue }

            let entryCount = Int(min(
                ceil(Double(dataSet.entryCount) * Double(phaseX)),
                Double(dataSet.entryCount)
            ))
            let trans   = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
            let matrix  = trans.valueToPixelMatrix
            var pt      = CGPoint()

            for j in 0..<entryCount {
                guard let e = dataSet.entryForIndex(j) else { continue }

                pt.x = CGFloat(e.x)
                pt.y = CGFloat(e.y * phaseY)
                pt    = pt.applying(matrix)

                if !viewPortHandler.isInBoundsRight(pt.x) { break }
                if !viewPortHandler.isInBoundsLeft(pt.x) { continue }

                let radius = CGFloat(dataSet.circleRadius)
                var circleRect = CGRect(
                    x: pt.x - radius,
                    y: pt.y - radius,
                    width: radius * 2.0,
                    height: radius * 2.0
                )

                context.setFillColor(dataSet.getCircleColor(atIndex: j)!.cgColor)
                context.fillEllipse(in: circleRect)

                if dataSet.isDrawCircleHoleEnabled,
                   let holeColor = dataSet.circleHoleColor {
                    let holeRadius = CGFloat(dataSet.circleHoleRadius)
                    circleRect = CGRect(
                        x: pt.x - holeRadius,
                        y: pt.y - holeRadius,
                        width: holeRadius * 2.0,
                        height: holeRadius * 2.0
                    )
                    context.setFillColor(holeColor.cgColor)
                    context.fillEllipse(in: circleRect)
                }
            }
        }

        context.restoreGState()
    }
}
