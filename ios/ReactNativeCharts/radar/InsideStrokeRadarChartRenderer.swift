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

    override func drawDataSet(context: CGContext, dataSet: RadarChartDataSetProtocol, mostEntries: Int) {
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

            let p = center.moving(distance: distance,
                                  atAngle: sliceangle * CGFloat(j) * CGFloat(phaseX) + chart.rotationAngle)

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
            context.setAlpha(1.0)

            context.beginPath()
            context.addPath(path)
            context.strokePath()
        }

        context.restoreGState()
    }
}
