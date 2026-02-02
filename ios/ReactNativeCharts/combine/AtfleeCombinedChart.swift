//
//  AtfleeCombinedChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//
//  Nested scrolling strategy:
//  - Always allow chart pan to begin (even vertical)
//  - dragYEnabled=false prevents vertical chart movement
//  - Allow simultaneous recognition so ScrollView can scroll
//

import UIKit
import DGCharts
import SwiftyJSON

class AtfleeCombinedChart: CombinedChartView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupForNestedScrolling()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupForNestedScrolling()
    }
    
    private func setupForNestedScrolling() {
        self.dragYEnabled = false
    }
    
    // MARK: - Gesture Recognizer Delegate
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    // Allow simultaneous recognition
    override func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
}
