//
//  AtfleeMarker.swift
//

import Foundation
import SwiftyJSON
import DGCharts

open class AtfleeMarker: MarkerView {

    // ────────────── ★ ① Fade-in 애니메이션용 프로퍼티 ★ ──────────────
    private var fadeStart: CFTimeInterval?
    private let fadeDuration: CFTimeInterval = 0.25
    fileprivate var arrowImage: UIImage?     // 이제 RN에서 주입된 이미지
    
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
        _paragraphStyle?.lineSpacing = 6     // ★ 원하는 패딩(px)만큼
    }
    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // ───────────────── drawRect / drawCenterRect 그대로 ─────────────────
    func drawRect(context: CGContext, point: CGPoint) -> CGRect {
        let width = _size.width
        let height = _size.height
        
        // 포인트 위 중앙에 표시될 원래 pt
        var pt = CGPoint(x: point.x - width/2,
                         y: point.y - height - 10)
        
        // ② 엣지 보정: 좌/우/상 경계 안으로
        if let chart = chartView {
            if pt.x < 8 {
                pt.x = 8
            }
            if pt.x + width > chart.bounds.size.width {
                pt.x = chart.bounds.size.width - width - 8
            }
            if pt.y < 8 {
                pt.y = 8
            }
        }
        
        let bgRect = CGRect(origin: pt, size: _size)
        drawCenterRect(context: context, rect: bgRect)
        
        // ③ 자식(draw) 로직은 bgRect 그대로 씁니다
        return bgRect
    }
    func drawCenterRect(context: CGContext, rect: CGRect) {
        context.saveGState()
        let roundRect = UIBezierPath(roundedRect: rect, byRoundingCorners:.allCorners,
                                     cornerRadii: CGSize(width: 7, height: 7))
        context.setFillColor(UIColor.white.cgColor)
        context.setShadow(offset: CGSize(width: 1.0, height: 5.0), blur: 7.5)
//        context.setBlendMode(.multiply)
        context.addPath(roundRect.cgPath)
        context.fillPath()
        context.restoreGState()
    }

    // ────────────── ★ ② draw(context:point:) 최소 패치 ★ ──────────────
    open override func draw(context: CGContext, point: CGPoint) {
        context.saveGState()
        
        // 페이드 인 진행률 계산
        var progress: CGFloat = 1
        if let start = fadeStart {
            progress = min(max(CGFloat((CACurrentMediaTime() - start) / fadeDuration), 0), 1)
            if progress < 1, let chart = chartView {
                DispatchQueue.main.async { chart.setNeedsDisplay() }
            }
        }
        let alpha = progress
        let yRise = 20 * (1 - progress)

        let chartHeight = chartView?.bounds.height ?? 0
        let showMarkerAbove = point.y > chartHeight * 0.35

        var markerPt = point
        let markerHeight = _size.height

        context.setAlpha(alpha)
        if showMarkerAbove {
            // 기존: tick 위에 marker
            markerPt.y = point.y - markerHeight * 0.8
            context.translateBy(x: 0, y: yRise)
        } else {
            // 신규: tick 아래에 marker
            markerPt.y = point.y + markerHeight * 1.35
            context.translateBy(x: 0, y: -yRise)
        }

        let rect = drawRect(context: context, point: markerPt)

        print("drawRect result origin:", rect.origin, "size:", rect.size)

        UIGraphicsPushContext(context)

        // 패딩값 정의
        let bgPadding: CGFloat = 8
        let paddedRect = rect.insetBy(dx: bgPadding, dy: bgPadding)
        
        // 타이틀 로그
        if let title = labelTitle, title.length > 0 {
            print("labelTitle:", title)
            
            title.draw(in: paddedRect, withAttributes: _drawTitleAttributes)
        } else {
            print("labelTitle is nil or empty")
        }

        // 단위 로그
        if let lbl = labelns, lbl.length > 0 {
            print("labelns:", lbl)
            lbl.draw(in: paddedRect, withAttributes: _drawAttributes)
        } else {
            print("labelns is nil or empty")
        }

        // 아이콘 로그
        if let img = imageEmotion {
            print("imageEmotion present")
            let iconRect = CGRect(
                origin: CGPoint(
                    x: rect.origin.x + (rect.width - CGFloat(imageSize)) / 2,
                    y: rect.origin.y + (rect.height - CGFloat(imageSize)) / 2 + 8
                ),
                size: CGSize(width: CGFloat(imageSize), height: CGFloat(imageSize))
            )
            img.draw(in: iconRect)
        } else {
            print("imageEmotion is nil")
        }

        // 화살표 이미지 로그
        if let img = arrowImage {
            let arrowSize: CGFloat = 8
            let bgPadding: CGFloat = 8
            let arrowRect = CGRect(
                x: rect.maxX - bgPadding - arrowSize,
                y: rect.midY - arrowSize/2,
                width: arrowSize,
                height: arrowSize
            )
            img.draw(in: arrowRect)
        }
        UIGraphicsPopContext()
        context.restoreGState()
    }
    // ────────────────────────────────────────────────────────────────

    // offsetForDrawing, drawCenterRect 등 원본 그대로 … (생략)

    // ────────────── ★ ③ refreshContent에 한 줄만 추가 ★ ──────────────
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        // 시작 시각을 기록
        if fadeStart == nil {
            fadeStart = CACurrentMediaTime()
        }

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

        // 전체 크기
        let titleSize = labelTitle?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        let labelSize = labelns?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        let maxWidth = max(titleSize.width, labelSize.width)
        let maxHeight = max(titleSize.height, labelSize.height)
        _labelSize = CGSize(width: maxWidth, height: maxHeight + 8)
        _size.width = _labelSize.width + self.insets.left + self.insets.right
        _size.height = _labelSize.height + self.insets.top + self.insets.bottom
        _size.width = max(minimumSize.width, _size.width)
        _size.height = max(minimumSize.height, _size.height)

        // 감정 이모티콘
        label = ""
        if let object = entry.data as? JSON {
            if object["markerEmotion"].exists() {
                label = object["markerEmotion"].stringValue;
            }
        }
        if label.isEmpty {
            imageEmotion = nil
            _size.height -= imageSize

            arrowImage = UIImage(named: "arrow_right_circle")
        } else {
            switch label {
            case "1":
                imageEmotion = UIImage(named: "emotion1")
            case "2":
                imageEmotion = UIImage(named: "emotion2")
            case "3":
                imageEmotion = UIImage(named: "emotion3")
            case "4":
                imageEmotion = UIImage(named: "emotion4")
            case "5":
                imageEmotion = UIImage(named: "emotion5")
            default:
                imageEmotion = nil
                _size.height -= imageSize
            }
        }
    }
    
    open override func removeFromSuperview() {
      super.removeFromSuperview()
      fadeStart = nil
    }
}
