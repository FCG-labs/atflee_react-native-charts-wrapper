//
//  NestedScrollingHelper.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//

import UIKit

class NestedScrollingHelper {
    /// Determines whether the chart's pan gesture should begin.
    /// Returns `false` if the gesture is primarily vertical, allowing the parent ScrollView to intercept.
    static func shouldRecognizeGesture(_ gestureRecognizer: UIGestureRecognizer, in view: UIView, panGesture: UIPanGestureRecognizer?) -> Bool {
        if let pan = panGesture, gestureRecognizer == pan {
            let velocity = pan.velocity(in: view)
            // If strictly vertical movement (y > x), reject the gesture
            if abs(velocity.y) > abs(velocity.x) {
                return false
            }
        }
        return true
    }
}
