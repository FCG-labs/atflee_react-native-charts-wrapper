//
//  AtfleeCombinedChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//

import UIKit
import DGCharts
import SwiftyJSON

class AtfleeCombinedChart: CombinedChartView {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Use NestedScrollingHelper to determine if we should consume the gesture
        // or let it pass through to the parent (e.g. ScrollView)
        let panGesture = gestureRecognizer as? UIPanGestureRecognizer
        if !NestedScrollingHelper.shouldRecognizeGesture(gestureRecognizer, in: self, panGesture: panGesture) {
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
