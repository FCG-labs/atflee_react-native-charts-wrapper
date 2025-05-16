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
    open var titleFont: UIFont?
    open var textColor: UIColor?
    open var textWeight: String?
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
    public init(color: UIColor, font: UIFont, textColor: UIColor, textAlign: NSTextAlignment, textWeight: String,titleFont: UIFont) {
        super.init(frame: .zero)
        self.color = color
        self.font = font
        self.titleFont = titleFont
        self.textColor = textColor
        self.textWeight = textWeight
        
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
                                     cornerRadii: CGSize(width: 8, height: 8))
        context.setFillColor(UIColor.white.cgColor)
        context.setShadow(offset: CGSize(width: 1.0, height: 4.0), blur: 7.5)
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

        // print("drawRect result origin:", rect.origin, "size:", rect.size)

        UIGraphicsPushContext(context)

        // 패딩값 정의
        let bgPadding: CGFloat = 8
        let paddedRect = rect.insetBy(dx: bgPadding, dy: bgPadding)
        
        // 타이틀 로그
        if let title = labelTitle, title.length > 0 {
            // print("labelTitle:", title)
            
            title.draw(in: paddedRect, withAttributes: _drawTitleAttributes)
        } else {
            // print("labelTitle is nil or empty")
        }

        // 단위 로그
        if let lbl = labelns, lbl.length > 0 {
            // print("labelns:", lbl)
//            lbl.draw(in: paddedRect, withAttributes: _drawAttributes)
            
            // 1️⃣ 텍스트 위치 계산
            var attrs = _drawAttributes
            // labelns의 width 측정 (폰트, 속성 적용)
            let labelSize = lbl.size(withAttributes: attrs)

            // labelns 위치: paddedRect에서 x좌표, y는 가운데 정렬
            let lblX = paddedRect.origin.x
            let lblY = paddedRect.midY - labelSize.height/2
            let lblRect = CGRect(
                x: lblX,
                y: lblY,
                width: labelSize.width,
                height: labelSize.height
            )
            lbl.draw(in: lblRect, withAttributes: attrs)

            // 2️⃣ arrowImage가 있다면 lbl 오른쪽에 바로 붙여서 그리기
            if let img = arrowImage {
                let arrowSize: CGFloat = 20
                let arrowPadding: CGFloat = 6
                let arrowX = lblRect.maxX + arrowPadding
                let arrowY = paddedRect.maxY - arrowSize
                let arrowRect = CGRect(x: arrowX, y: arrowY, width: arrowSize, height: arrowSize)
                img.draw(in: arrowRect)
            }
        } else {
            // print("labelns is nil or empty")
        }

        // 아이콘 로그
        if let img = imageEmotion {
            // print("imageEmotion present")
            let iconRect = CGRect(
                origin: CGPoint(
                    x: rect.origin.x + (rect.width - CGFloat(imageSize)) / 2,
                    y: rect.origin.y + (rect.height - CGFloat(imageSize)) / 2 + 8
                ),
                size: CGSize(width: CGFloat(imageSize), height: CGFloat(imageSize))
            )
            img.draw(in: iconRect)
        } else {
            // print("imageEmotion is nil")
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

        print("🟦 [AtfleeMarker] refreshContent called!")
        print("entry.x: \(entry.x), entry.y: \(entry.y)")
        
        if let data = entry.data {
            print("entry.data: \(data)")
        } else {
            print("entry.data: nil")
        }
        
        // entry의 타입/상속분기(Candle 등)도 확인
        if let candleEntry = entry as? CandleChartDataEntry {
            print("Candle Entry - open: \(candleEntry.open), close: \(candleEntry.close), high: \(candleEntry.high), low: \(candleEntry.low)")
        }
        
        print("highlight.x: \(highlight.x), highlight.y: \(highlight.y), stackIndex: \(highlight.stackIndex)")
        


        
        var label : String
        var decimalPlaces = "0"
        var markerUnit = ""
        var markerString = ""

        // 날짜(타이틀)
        label = chartView?.xAxis.valueFormatter?.stringForValue(entry.x, axis: chartView?.xAxis) ?? ""
        labelTitle = label as NSString
        
        if let object = entry.data as? JSON {
            if object["markerTitle"].exists() {
                labelTitle = object["markerTitle"].stringValue  as NSString
            }
        }

        _drawTitleAttributes.removeAll()
        _drawTitleAttributes[NSAttributedString.Key.font] = self.titleFont
        _drawTitleAttributes[NSAttributedString.Key.paragraphStyle] = _paragraphStyle
        _drawTitleAttributes[NSAttributedString.Key.foregroundColor] = #colorLiteral(red: 0.9515632987, green: 0.4954123497, blue: 0.1712778509, alpha: 1)
        let titleSize = labelTitle?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        
        //
        if let object = entry.data as? JSON {
            // 단위
            if object["markerUnit"].exists() {
                markerUnit = object["markerUnit"].stringValue;
                if highlight.stackIndex != -1 && object["markerUnit"].array != nil {
                    markerUnit = object["markerUnit"].arrayValue[highlight.stackIndex].stringValue
                }
            }
            
            // marker 글자
            if object["markerUnit"].exists() {
                markerString = object["marker"].stringValue;
                if highlight.stackIndex != -1 && object["marker"].array != nil {
                    markerString = object["marker"].arrayValue[highlight.stackIndex].stringValue
                }
            }
            
            // decimal places
            if object["decimalPlaces"].exists() {
                decimalPlaces = object["decimalPlaces"].stringValue;
                if highlight.stackIndex != -1 && object["decimalPlaces"].array != nil {
                    decimalPlaces = object["decimalPlaces"].arrayValue[highlight.stackIndex].stringValue
                }
            }
        }

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
        _drawAttributes[NSAttributedString.Key.paragraphStyle] = _paragraphStyle
        _drawAttributes[NSAttributedString.Key.foregroundColor] = self.textColor

        let isBold = textWeight == "bold"
        let baseFont: UIFont = self.font ?? UIFont.systemFont(ofSize: 12.0)
        let fontSize = baseFont.pointSize

        let labelFont: UIFont = isBold
            ? UIFont.boldSystemFont(ofSize: fontSize)
            : baseFont

        _drawAttributes[.font] = labelFont

        // 전체 크기
        let labelSize = labelns?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        let maxWidth = max(titleSize.width, labelSize.width)
        let maxHeight = max(titleSize.height, labelSize.height)
        _labelSize = CGSize(width: maxWidth, height: maxHeight + 8) // 패딩줬기때문에 라벨 하단 짤려서 넣어줘야함
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
            
            if let _ = arrowImage {
                let arrowSize: CGFloat = 20   // draw에서 쓴 arrowSize와 맞춰야함
                let arrowPadding: CGFloat = 6
                _size.width += arrowSize + arrowPadding
            }
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
