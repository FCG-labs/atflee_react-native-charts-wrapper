//
//  AtfleeCombinedChart.swift
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
        self.renderer = RoundedCombinedChartRenderer(
            chart: self,
            animator: self.chartAnimator,
            viewPortHandler: self.viewPortHandler,
            barRadius: 0
        )
    }
    
    // MARK: - Gesture Recognizer Delegate
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGesture.velocity(in: self)
            let translation = panGesture.translation(in: self)
            // velocity+translation 합산: 초기 zero 벡터 엣지케이스 보완
            let vx = abs(velocity.x) + abs(translation.x)
            let vy = abs(velocity.y) + abs(translation.y)
            // 수직 우세 → ScrollView에 위임, 차트 제스처 시작 안 함
            if vy > vx {
                return false
            }
            return true
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    // pan+pan 동시 허용: 차트가 수평 pan을 처리할 때 부모 ScrollView도 함께 작동
    // (수직 제스처는 gestureRecognizerShouldBegin에서 차단되므로 중복 동작 없음)
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
