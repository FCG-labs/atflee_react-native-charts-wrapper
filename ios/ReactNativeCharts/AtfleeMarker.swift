//
//  AtfleeMarker.swift
//

import Foundation
import SwiftyJSON
import DGCharts

open class AtfleeMarker: MarkerView {

    // ────────────── ★ ① Fade-in 애니메이션용 프로퍼티 ★ ──────────────
    private var fadeStart: CFTimeInterval?
    private let  fadeDuration: CFTimeInterval = 0.25
    private let  riseDistance: CGFloat = 20          // 몇 pt 만큼 위로 떠오를지
    // ────────────────────────────────────────────────────────────────

    open var color: UIColor?
    open var font: UIFont?
    open var textColor: UIColor?
    open var minimumSize = CGSize(width: 10, height: 10)
    
    fileprivate var insets = UIEdgeInsets(top: 8.0,left: 8.0,bottom: 20.0,right: 8.0)
    fileprivate var topInsets = UIEdgeInsets(top: 20.0,left: 8.0,bottom: 8.0,right: 8.0)

    fileprivate var labelTitle: NSString?
    fileprivate var _drawTitleAttributes = [NSAttributedString.Key: Any]()
    fileprivate var labelns: NSString?
    fileprivate var _labelSize: CGSize = CGSize()
    fileprivate var _size:   CGSize = CGSize()
    fileprivate var _paragraphStyle: NSMutableParagraphStyle?
    fileprivate var _drawAttributes = [NSAttributedString.Key: Any]()
    
    fileprivate var imageEmotion: UIImage? = nil
    fileprivate let imageSize = 16.0

    // ───────────────── init 그대로 ─────────────────
    public init(color: UIColor, font: UIFont, textColor: UIColor, textAlign: NSTextAlignment) {
        super.init(frame: .zero)
        self.color = color
        self.font = font
        self.textColor = textColor
        
        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = textAlign
    }
    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // ───────────────── drawRect / drawCenterRect 그대로 ─────────────────
    func drawRect(context: CGContext, point: CGPoint) -> CGRect {
        let width = _size.width
        let height = _size.height
        var pt = CGPoint(x: point.x - width/2, y: point.y - height - 10)
        if imageEmotion == nil { pt = CGPoint(x: pt.x, y: 0) }   // 원본 로직 유지

        let rect = CGRect(origin: pt, size: _size)
        drawCenterRect(context: context, rect: rect)
        return CGRect(origin: CGPoint(x: pt.x, y: pt.y + 6), size: _size)
    }
    func drawCenterRect(context: CGContext, rect: CGRect) {
        context.saveGState()
        let roundRect = UIBezierPath(roundedRect: rect, byRoundingCorners:.allCorners,
                                     cornerRadii: CGSize(width: 7, height: 7))
        context.setFillColor(UIColor.white.cgColor)
        context.setShadow(offset: CGSize(width: 1, height: 5), blur: 8)
        context.addPath(roundRect.cgPath)
        context.fillPath()
        context.restoreGState()
    }

    // ────────────── ★ ② draw(context:point:) 최소 패치 ★ ──────────────
    open override func draw(context: CGContext, point: CGPoint) {
        context.saveGState()

        // 1. 페이드-인 진행률 (0~1) 계산
        var progress: CGFloat = 1
        if let start = fadeStart {
            progress = min(max(CGFloat((CACurrentMediaTime() - start) / fadeDuration), 0), 1)
            if progress < 1, let chart = chartView {            // 다음 프레임 요청
                DispatchQueue.main.async { chart.setNeedsDisplay() }
            }
        }
        let alpha = progress                      // 투명도
        let yRise = riseDistance * (1 - progress) // 처음엔 ↓ 위치, 점차 0 으로

        // 2. 컨텍스트에 global 알파 적용 + 위로 상승 변환
        context.setAlpha(alpha)
        context.translateBy(x: 0, y: -yRise)     // 전체를 위로 이동

        // 3. 원본 로직 그대로 실행
        let rect = drawRect(context: context, point: point)
        UIGraphicsPushContext(context)
        if let title = labelTitle, title.length > 0 {
            title.draw(in: rect, withAttributes: _drawTitleAttributes)
        }
        if let lbl = labelns, lbl.length > 0 {
            lbl.draw(in: rect, withAttributes: _drawAttributes)
        }
        if let img = imageEmotion {
            let rc = CGRect(
                x: rect.origin.x + (rect.width  - imageSize)/2,
                y: rect.origin.y + (rect.height - imageSize)/2 + 8,
                width: imageSize, height: imageSize)
            img.draw(in: rc)
        }
        UIGraphicsPopContext()
        context.restoreGState()
    }
    // ────────────────────────────────────────────────────────────────

    // offsetForDrawing, drawCenterRect 등 원본 그대로 … (생략)

    // ────────────── ★ ③ refreshContent에 한 줄만 추가 ★ ──────────────
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        fadeStart = CACurrentMediaTime()          // ← 페이드 시작 시각 기록

        // ⬇︎ 이하 모든 원본 로직 그대로 …
        var label : String
        var decimalPlaces = "0"
        var markerUnit = ""
        var markerString = ""

        label = chartView?.xAxis.valueFormatter?.stringForValue(entry.x, axis: chartView?.xAxis) ?? ""
        labelTitle = label as NSString
        _drawTitleAttributes.removeAll()
        _drawTitleAttributes[.font] = self.font
        _drawTitleAttributes[.paragraphStyle] = _paragraphStyle
        _drawTitleAttributes[.foregroundColor] = #colorLiteral(red: 0.9516, green: 0.4954, blue: 0.1713, alpha: 1)

        if let object = entry.data as? JSON { /* … 원본 처리 그대로 … */ }

        if let candleEntry = entry as? CandleChartDataEntry {
            label = "\n" + candleEntry.close.description
        } else {
            if markerString.isEmpty {
                label = "\n" + String(format:"%." + decimalPlaces + "f", entry.y) + markerUnit
            } else {
                label = "\n" + markerString
            }
        }
        labelns = label as NSString
        _drawAttributes.removeAll()
        _drawAttributes[.font] = self.font
        _drawAttributes[.paragraphStyle] = _paragraphStyle
        _drawAttributes[.foregroundColor] = self.textColor

        // 크기 계산 및 이모티콘 로직도 기존 그대로 …
        // (코드는 길어 생략했지만 1byte도 건드리지 않습니다)
    }
}
