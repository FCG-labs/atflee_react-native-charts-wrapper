//
//  AtfleeBarChart.swift
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

private final class ChartPanGatekeeper: UIPanGestureRecognizer {
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
            // 수평 확정: gatekeeper fail → DGCharts pan 시작 허용
            state = .failed
        }
        // 수직 확정: gatekeeper 유지 → DGCharts pan require(toFail) 에 의해 영구 차단
    }

    override func reset() {
        super.reset()
        directionLocked = false
    }
}

// MARK: - AtfleeBarChart

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

        let gatekeeper = ChartPanGatekeeper()
        gatekeeper.cancelsTouchesInView = false
        gatekeeper.delegate = self
        addGestureRecognizer(gatekeeper)

        // DGCharts pan은 gatekeeper가 fail(수평)해야만 시작 가능
        for recognizer in gestureRecognizers ?? [] where recognizer !== gatekeeper {
            if recognizer is UIPanGestureRecognizer {
                recognizer.require(toFail: gatekeeper)
            }
        }
    }

    // MARK: - Gesture Recognizer Delegate

    // gatekeeper + ScrollView pan 동시 인식 허용 (ScrollView가 수직 스크롤 계속 가능)
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
