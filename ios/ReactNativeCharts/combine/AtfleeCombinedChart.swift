//
//  AtfleeCombinedChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//
//  Nested scrolling strategy:
//  - ChartPanGatekeeper: gesture 전 구간에서 방향 감시
//    · 수평 확정 → gatekeeper.fail() → DGCharts pan 허용
//    · 수직 확정 → gatekeeper 유지(recognized) → DGCharts pan 영구 차단(require toFail)
//  - dragYEnabled=false: 혹시 pan이 시작돼도 수직 chart 이동 차단
//

import UIKit
import DGCharts
import SwiftyJSON

// MARK: - Gatekeeper

private final class CombinedChartPanGatekeeper: UIPanGestureRecognizer {
    private var directionLocked = false

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
