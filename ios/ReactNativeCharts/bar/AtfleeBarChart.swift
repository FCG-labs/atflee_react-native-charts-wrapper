//
//  AtfleeBarChart.swift
//  reactNativeCharts
//
//  Created by Cascade on 2025/01/07.
//
//  Nested scrolling strategy (RN ScrollView 안 chart):
//
//  Root cause #1 — dragYEnabled bridge 누락:
//    JS prop `dragYEnabled={false}` 가 native까지 전달되지 않음
//    (RNBarLineChartManagerBridge.h에 export 없음).
//    따라서 JS의 `dragEnabled={true}` 프롭이 setDragEnabled(true) 호출→
//    DGCharts setter가 _dragXEnabled, _dragYEnabled 둘 다 true로 뎏음.
//    → dragEnabled setter override로 Y는 영구히 false로 고정.
//
//  Root cause #2 — deceleration 우회:
//    DGCharts deceleration은 별도 NSUIDisplayLink로 돌아감.
//    stopDeceleration()은 panGestureRecognized .began 시점에만 호출됨.
//    Gatekeeper가 수직 제스처를 차단하면 DGCharts pan이 .began으로 안 가므로
//    이전 horizontal pan 후에 시작된 deceleration이 멈추지 않음.
//    → gatekeeper.touchesBegan에서 chart.stopDeceleration() 강제 호출.
//
//  Gatekeeper:
//    · 수평 확정 → gatekeeper.fail() → DGCharts pan 허용
//    · 수직 확정 → gatekeeper 유지 → DGCharts pan require(toFail)로 차단
//

import UIKit
import DGCharts
import SwiftyJSON

// MARK: - Gatekeeper

private final class ChartPanGatekeeper: UIPanGestureRecognizer {
    weak var chart: BarLineChartViewBase?
    private var directionLocked = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        // 새 touch 시작 시 deceleration 강제 정지.
        // gatekeeper가 수직 확정 시 DGCharts pan을 차단하면 .began이 안 오므로
        // DGCharts 자체 stopDeceleration이 동작 안 함.
        chart?.stopDeceleration()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard !directionLocked, state == .began || state == .changed else { return }
        let t = translation(in: view)
        let tx = abs(t.x)
        let ty = abs(t.y)
        // UIScrollView nested pattern:
        //  - 최소 10pt 이동 후에만 방향 판단 (자연스러운 손가락 움직임의 noise 하한)
        //  - 명백한 horizontal 우세 (압도적 2배 이상) 시에만 chart pan 허용
        //  - 그 외 모든 경우(vertical, diagonal, ambiguous) → gatekeeper 유지 → parent scroll 승
        guard tx + ty > 10 else { return }
        directionLocked = true
        // 명백한 horizontal일 때만 release. 그 외에는 stay alive하여 DGCharts pan 영구 차단.
        if tx > ty * 2.0 {
            state = .failed
        }
    }

    override func reset() {
        super.reset()
        directionLocked = false
    }
}

// MARK: - AtfleeBarChart

class AtfleeBarChart: BarChartView {

    // Root cause #1 fix: dragEnabled setter는 _dragXEnabled만 제어, _dragYEnabled는 영구히 false.
    // RN bridge에 dragYEnabled setter가 없으므로 JS 프롭으로 강제할 수 없음.
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

        let gatekeeper = ChartPanGatekeeper()
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
