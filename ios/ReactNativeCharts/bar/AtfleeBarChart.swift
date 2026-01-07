//
//  AtfleeBarChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//

import UIKit
import DGCharts
import SwiftyJSON

class AtfleeBarChart: BarChartView {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Use NestedScrollingHelper to determine if we should consume the gesture
        // or let it pass through to the parent (e.g. ScrollView)
        if !NestedScrollingHelper.shouldRecognizeGesture(gestureRecognizer, in: self, panGesture: self.panGestureRecognizer) {
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
