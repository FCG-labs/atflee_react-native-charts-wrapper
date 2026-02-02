//
//  AtfleeBarChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//
//  Nested scrolling strategy:
//  - Override gestureRecognizerShouldBegin with lenient vertical detection
//  - DGCharts' shouldRecognizeSimultaneouslyWith allows ScrollView coordination
//

import UIKit
import DGCharts
import SwiftyJSON

class AtfleeBarChart: BarChartView {
    
    // Vertical scroll threshold: lower = more lenient toward vertical
    // 0.5 means ~27° from vertical axis triggers ScrollView (vs 45° default)
    private let verticalThreshold: CGFloat = 0.5
    
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
        print("[iOS] AtfleeBarChart: Lenient vertical scroll (~27°)")
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocity(in: self)
            // More lenient: abs(y) > abs(x) * 0.5 means ~27° from vertical
            // Default DGCharts uses abs(y) > abs(x) which is 45°
            if abs(velocity.y) > abs(velocity.x) * verticalThreshold {
                return false  // Let ScrollView handle
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}
