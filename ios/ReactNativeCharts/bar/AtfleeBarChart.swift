//
//  AtfleeBarChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//
//  Nested scrolling strategy:
//  - Reject vertical-dominant pan so the outer ScrollView can scroll
//  - Horizontal-dominant pan: chart handles (vertical ScrollView won't interfere)
//  - dragYEnabled=false prevents vertical chart movement
//

import UIKit
import DGCharts
import SwiftyJSON

class AtfleeBarChart: BarChartView {
    
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
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGesture.velocity(in: self)
            // 수직 우세 → ScrollView에 위임, 차트 제스처 시작 안 함
            if abs(velocity.y) > abs(velocity.x) {
                return false
            }
            return true
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    // 방향 분기는 gestureRecognizerShouldBegin에서 처리되므로 동시 인식 불필요
    override func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
}
