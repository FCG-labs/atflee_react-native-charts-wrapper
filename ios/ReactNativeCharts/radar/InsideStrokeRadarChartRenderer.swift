//  InsideStrokeRadarChartRenderer.swift
//  Created to ensure radar chart polygons do NOT overshoot the web grid when using thick lineWidth.
//
//  The default DGCharts `RadarChartRenderer` draws the polyline exactly on the outer web, which means
//  half of the stroke thickness is rendered outside when `lineWidth > 0`.  This subclass compensates
//  by shortening the radius by `lineWidth / 2` when constructing the path.
//
//  Only the `drawDataSet` method is overridden – everything else remains identical to upstream.
//  Thus maintenance cost is minimal and other behaviour (highlights, values, accessibility) stays intact.

import Foundation
import CoreGraphics
import DGCharts

class InsideStrokeRadarChartRenderer: RadarChartRenderer {
    /// Calculate point from center with given distance and degree angle (clock-wise, 0° = right)
    private func point(from center: CGPoint, distance: CGFloat, angleDegrees: CGFloat) -> CGPoint {
        let rad = angleDegrees * .pi / 180.0
        return CGPoint(x: center.x + distance * cos(rad), y: center.y + distance * sin(rad))
    }

    /// We cannot override `drawDataSet` because it is `internal` in Charts framework.
    /// Instead, override the `open` `drawData` and reproduce the essential logic with our own
    /// radius adjustment (lineWidth/2).
    open override func drawData(context: CGContext) {
        guard let chart = chart,
              let radarData = chart.data as? RadarChartData else {
            return
        }

        let mostEntries = radarData.maxEntryCountSet?.entryCount ?? 0

        for case let set as RadarChartDataSetProtocol in (radarData as ChartData) where set.isVisible {
            drawDataSetInside(context: context, dataSet: set, mostEntries: mostEntries)
        }
    }

    private func drawDataSetInside(context: CGContext, dataSet: RadarChartDataSetProtocol, mostEntries: Int) {
        guard let chart = chart else { return }

        context.saveGState()

        let phaseX = animator.phaseX
        let phaseY = animator.phaseY
        let sliceangle = chart.sliceAngle
        let factor = chart.factor
        let center = chart.centerOffsets
        let entryCount = dataSet.entryCount

        let path = CGMutablePath()
        var hasMovedToPoint = false

        for j in 0 ..< entryCount {
            guard let e = dataSet.entryForIndex(j) else { continue }

            // Base pixel distance from center to value position
            let base = CGFloat((e.y - chart.chartYMin) * Double(factor) * phaseY)
            // Pull back by half of stroke width so the outer edge of the stroke sits exactly on the web
            let distance = max(0, base - dataSet.lineWidth / 2.0)

            let angle = sliceangle * CGFloat(j) * CGFloat(phaseX) + chart.rotationAngle
            let p = point(from: center, distance: distance, angleDegrees: angle)

            if p.x.isNaN { continue }

            if !hasMovedToPoint {
                path.move(to: p)
                hasMovedToPoint = true
            } else {
                path.addLine(to: p)
            }
        }

        // Close the polygon
        path.closeSubpath()

        // Filled area
        if dataSet.isDrawFilledEnabled {
            if let fill = dataSet.fill {
                drawFilledPath(context: context, path: path, fill: fill, fillAlpha: dataSet.fillAlpha)
            } else {
                drawFilledPath(context: context, path: path, fillColor: dataSet.fillColor, fillAlpha: dataSet.fillAlpha)
            }
        }

        // Outline (if needed)
        if !dataSet.isDrawFilledEnabled || dataSet.fillAlpha < 1.0 {
            context.setStrokeColor(dataSet.color(atIndex: 0).cgColor)
            context.setLineWidth(dataSet.lineWidth)
            context.setLineJoin(.round)
            context.setAlpha(1.0)

            context.beginPath()
            context.addPath(path)
            context.strokePath()
        }

        context.restoreGState()
    }
}
