import Foundation
import CoreGraphics
import DGCharts

/// 보이는 점 개수로 점 반지름·선 굵기·중간 점 표시를 매 프레임 정하는 선 데이터셋.
///
/// JS 는 기준값(`densityStyle`)만 한 번 넘기고, `NoClipLineChartRenderer` 가 그릴 때마다
/// 지금 보이는 구간(lowestVisibleX~highestVisibleX)으로 계산한다. JS 가 보이는 구간을 추측해
/// 조형을 데이터로 다시 보내면 화면과 비동기로만 맞아 탭 전환·핀치 때 어긋난 프레임이 생긴다.
/// `densityStyle` 이 없으면 `LineChartDataSet` 과 똑같이 동작한다.
open class DensityStyledLineChartDataSet: LineChartDataSet {

    /// 식은 앳플리 「변화 전체」 화면의 JS 와 같다(ScaleFullChangesPage.tsx chartPointRadius · chartLineWidth ·
    /// chartEndPointRadius, 걸쇠 30/28). 값의 단위는 iOS pt / Android dp.
    public struct DensityStyle {
        /// 이 개수가 보일 때의 점 반지름·선 굵기가 기준값이자 상한이다.
        public var referenceCount: Double = 7
        public var circleRadius: Double = 4
        public var lineWidth: Double = 3
        public var minLineWidth: Double = 1.4
        public var lineWidthExponent: Double = 0.6
        /// 보이는 점이 이 수를 넘으면 중간 점을 숨기고 보이는 양 끝 점만 그린다.
        public var endsOnlyAbove: Double = 30
        /// 숨긴 뒤에는 이 수를 넘는 동안 계속 숨긴다 — 경계에서 ±1 로 떨릴 때 점이 깜빡이지 않게.
        public var endsOnlyReleaseAbove: Double = 28
        public var endCircleRadiusRatio: Double = 0.85
        public var minEndCircleRadius: Double = 2

        public init() {}
    }

    /// 한 프레임의 조형. 렌더러가 선을 그리기 전에 채우고, 같은 프레임의 점·값 라벨이 읽는다.
    /// 반지름·굵기는 데이터셋의 `circleRadius` · `lineWidth` 에 바로 싣는다 — 중간 점을 숨기는 프레임에서는
    /// `circleRadius` 가 곧 끝 점 반지름이라, 그리는 쪽은 어느 점을 그릴지만 가리면 된다.
    public struct DensityFrame {
        public let visibleCount: Int
        public let endsOnly: Bool
        public let firstVisibleIndex: Int
        public let lastVisibleIndex: Int
    }

    public var densityStyle: DensityStyle? {
        didSet {
            endsOnlyLatched = false
            densityFrame = nil
        }
    }

    public private(set) var densityFrame: DensityFrame?
    private var endsOnlyLatched = false

    /// 보이는 x 구간으로 이번 프레임의 조형을 정하고 `lineWidth` · `circleRadius` 에 싣는다.
    /// 중간 점을 숨기는 프레임이면 `circleRadius` 는 끝 점 반지름이다.
    /// 구간에 점이 하나도 없으면(점 사이 틈으로 확대) 앱 JS 와 같이 1개로 판정한다.
    @discardableResult
    open func applyDensityStyle(lowestVisibleX: Double, highestVisibleX: Double) -> DensityFrame? {
        guard let style = densityStyle, entryCount > 0, highestVisibleX >= lowestVisibleX else { return densityFrame }

        let first = entryIndex(x: lowestVisibleX, closestToY: .nan, rounding: .up)
        let last = entryIndex(x: highestVisibleX, closestToY: .nan, rounding: .down)
        let visible = first >= 0 && last >= first
            && (entryForIndex(first).map { $0.x >= lowestVisibleX - 1e-6 } ?? false)
            && (entryForIndex(last).map { $0.x <= highestVisibleX + 1e-6 } ?? false)
        let count = visible ? last - first + 1 : 1
        let ratio: Double
        if count > 1 && style.referenceCount > 1 {
            ratio = ((style.referenceCount - 1) / Double(count - 1)).squareRoot()
        } else {
            ratio = 1
        }
        // ChartDataSet 은 컬렉션을 따르므로 한정자 없는 min·max 는 컬렉션 메서드로 잡혀 컴파일되지 않는다.
        let radius = Swift.min(style.circleRadius, style.circleRadius * ratio)
        let width = Swift.min(style.lineWidth, Swift.max(style.minLineWidth, style.lineWidth * pow(ratio, style.lineWidthExponent)))
        let endsOnly = endsOnlyLatched
            ? Double(count) > style.endsOnlyReleaseAbove
            : Double(count) > style.endsOnlyAbove
        endsOnlyLatched = endsOnly
        let endRadius = Swift.max(
            style.minEndCircleRadius,
            style.circleRadius * style.endCircleRadiusRatio * (style.lineWidth > 0 ? width / style.lineWidth : 1)
        )

        lineWidth = CGFloat(width)
        circleRadius = CGFloat(endsOnly ? endRadius : radius)
        let frame = DensityFrame(
            visibleCount: count,
            endsOnly: endsOnly,
            firstVisibleIndex: visible ? first : -1,
            lastVisibleIndex: visible ? last : -1
        )
        densityFrame = frame
        return frame
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! DensityStyledLineChartDataSet
        copy.densityStyle = densityStyle
        return copy
    }
}
