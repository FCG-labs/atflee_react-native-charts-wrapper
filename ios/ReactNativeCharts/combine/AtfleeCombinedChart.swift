//
//  AtfleeCombinedChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//
//  Nested scrolling strategy (RN ScrollView 안 chart) — AtfleeBarChart와 동일 패턴.
//  Root causes:
//    #1 dragYEnabled bridge 누락 → dragEnabled setter override로 Y는 영구히 false
//    #2 deceleration display link 우회 → gatekeeper.touchesBegan에서 stopDeceleration
//

import UIKit
import DGCharts
import SwiftyJSON

// MARK: - Gatekeeper

private final class CombinedChartPanGatekeeper: UIPanGestureRecognizer {
    weak var chart: BarLineChartViewBase?
    private var directionLocked = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        chart?.stopDeceleration()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard !directionLocked, state == .began || state == .changed else { return }
        let v = velocity(in: view)
        let t = translation(in: view)
        let vx = abs(v.x) + abs(t.x)
        let vy = abs(v.y) + abs(t.y)
        guard vx + vy > 5 else { return }
        directionLocked = true
        if vx > vy {
            state = .failed
        }
    }

    override func reset() {
        super.reset()
        directionLocked = false
    }
}

// MARK: - AtfleeCombinedChart

class AtfleeCombinedChart: CombinedChartView {

    // Root cause #1 fix: dragEnabled setter는 _dragXEnabled만 제어, _dragYEnabled는 영구히 false.
    override var dragEnabled: Bool {
        get { return super.dragXEnabled }
        set {
            super.dragXEnabled = newValue
            super.dragYEnabled = false
        }
    }

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

        let gatekeeper = CombinedChartPanGatekeeper()
        gatekeeper.chart = self
        gatekeeper.cancelsTouchesInView = false
        gatekeeper.delegate = self
        addGestureRecognizer(gatekeeper)

        for recognizer in gestureRecognizers ?? [] where recognizer !== gatekeeper {
            if recognizer is UIPanGestureRecognizer {
                recognizer.require(toFail: gatekeeper)
            }
        }
    }

    // MARK: - Gesture Recognizer Delegate

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
