//
//  AtfleeMarker.swift
//

import Foundation
import SwiftyJSON
import DGCharts

private extension String {
    var containsEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji }
    }
}

private let showAboveThreshold: CGFloat = 0.2

open class AtfleeMarker: MarkerView {

    // ────────────── ★ ① Fade-in 애니메이션용 프로퍼티 ★ ──────────────
    private var fadeStart: CFTimeInterval?
    private let fadeDuration: CFTimeInterval = 0.25
    fileprivate var arrowImage: UIImage?     // 이제 RN에서 주입된 이미지
    
    /// 1. 마지막으로 표시된 마커 배경의 프레임
    fileprivate(set) var lastBgRect: CGRect = .zero

    /// 2. 마지막으로 선택된 데이터 엔트리
    fileprivate(set) var lastEntry: ChartDataEntry?
    
    open var color: UIColor?
    open var font: UIFont?
    open var titleFont: UIFont?
    open var textColor: UIColor?
    open var textWeight: String?
    open var minimumSize = CGSize(width: 10, height: 10)
    /// arrow 표시 여부
    open var arrowHidden: Bool = false

    
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
    fileprivate let imageSize = 20.0

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

    
    private func adjustedMarkerPoint(for point: CGPoint, chartHeight: CGFloat) -> CGPoint {
        let iconExists = imageEmotion != nil
        let showAbove = point.y > chartHeight * showAboveThreshold

        var markerPt = point
        let markerHeight = _size.height

        if showAbove {
            if iconExists {
                markerPt.y = markerHeight
            } else {
                markerPt.y = point.y - markerHeight * 0.8
            }
        } else {
            if iconExists {
                markerPt.y = point.y - markerHeight * 0.8
            } else {
                markerPt.y = point.y + markerHeight * 1.35
            }
        }
        return markerPt
    }
    
    // draw() 에서 마커 위치를 직접 계산하기 때문에 기본 offset 로직과
    // RoundedBarChartRenderer 의 하이라이트 라인이 맞지 않는 문제가 있었다.
    // drawHighlighted 에서는 marker.offsetForDrawing(atPoint:) 의 값을 이용해
    // 수직 라인의 시작점을 계산하므로, draw() 와 동일한 위치 계산을 여기서도
    // 수행하여 일관된 오프셋을 돌려준다.
    open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        var markerPt = point
        let markerHeight = _size.height
        let chartHeight = chartView?.bounds.height ?? 0
        let iconExists = imageEmotion != nil

        let showMarkerAbove = point.y > chartHeight * showAboveThreshold

        if showMarkerAbove {
            if iconExists {
                markerPt.y = markerHeight
            } else {
                markerPt.y = point.y - markerHeight * 0.8
            }
        } else {
            if iconExists {
                markerPt.y = point.y - markerHeight * 0.8
            } else {
                markerPt.y = point.y + markerHeight * 1.35
            }
        }

        var pt = CGPoint(
            x: markerPt.x - _size.width / 2,
            y: markerPt.y - _size.height - 10
        )

        if let chart = chartView {
            if pt.x < 8 { pt.x = 8 }
            if pt.x + _size.width > chart.bounds.size.width {
                pt.x = chart.bounds.size.width - _size.width - 8
            }
            if pt.y < 8 { pt.y = 8 }
        }

        let offsetX = pt.x - point.x
        let offsetY = pt.y - point.y
        return CGPoint(x: offsetX, y: offsetY)
    }

    
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
            if pt.y + height > chart.bounds.size.height {
                pt.y = chart.bounds.size.height - height
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

        let iconExists = imageEmotion != nil
        let arrowExists = arrowImage != nil // 항상 true(상시 표시)
        
        // 기존 페이드 인/위치 논리 유지
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
        
        let markerPt = adjustedMarkerPoint(for: point, chartHeight: chartHeight)
        let showMarkerAbove = point.y > chartHeight * showAboveThreshold

        context.setAlpha(alpha)
        if showMarkerAbove {
            context.translateBy(x: 0, y: -yRise)
        }

        let rect = drawRect(context: context, point: markerPt)
        self.lastBgRect = rect

        UIGraphicsPushContext(context)

        // 기본 padding 및 크기 정의
        let bgPadding: CGFloat = 8
        let paddedRect = rect.insetBy(dx: bgPadding, dy: bgPadding)
        let itemSpacing: CGFloat = 8
        let arrowSize: CGFloat = 20
        let iconSize: CGFloat = CGFloat(imageSize)

        // label, icon, arrowImage width 측정 (좌→우 순서 고정)
        var labelSize = CGSize.zero
        if let lbl = labelns, lbl.length > 0 {
            labelSize = lbl.size(withAttributes: _drawAttributes)
        }

        // 총 width 계산 (존재하는 요소만)
        var totalWidth: CGFloat = 0
        if labelSize.width > 0 { totalWidth += labelSize.width }
        if iconExists { totalWidth += iconSize }
        if arrowExists { totalWidth += arrowSize }
        // 간격 계산 (존재하는 요소 개수-1 만큼)
        let itemCount = [labelSize.width > 0, iconExists, arrowExists].filter { $0 }.count
        totalWidth += itemSpacing * CGFloat(max(itemCount - 1, 0))

        // x좌표 시작점 계산
        let startX = paddedRect.origin.x
        var currX = startX
        let baseY = paddedRect.maxY - labelSize.height // arrow, icon, label 모두 같은 Y축 기준

        // labelns
        if labelSize.width > 0 {
            let labelRect = CGRect(x: currX, y: baseY, width: labelSize.width, height: labelSize.height)
            labelns?.draw(in: labelRect, withAttributes: _drawAttributes)
            currX += labelSize.width + itemSpacing
        }

        // imageEmotion
        if let img = imageEmotion {
            let iconY = baseY + (labelSize.height - iconSize)
            let iconRect = CGRect(x: currX, y: iconY, width: iconSize, height: iconSize)
            img.draw(in: iconRect)
            currX += iconSize + itemSpacing
        }

        // arrowImage (항상 표시)
        if let img = arrowImage {
            let arrowY = baseY + (labelSize.height - arrowSize) / 2
            let arrowRect = CGRect(x: currX, y: arrowY, width: arrowSize, height: arrowSize)
            img.draw(in: arrowRect)
        }

        // 타이틀(기존 방식 그대로)
        if let title = labelTitle, title.length > 0 {
            title.draw(in: paddedRect, withAttributes: _drawTitleAttributes)
        }

        UIGraphicsPopContext()
        context.restoreGState()

        if let entry = self.lastEntry {
            createOverlayButtonIfNeeded(entry)
        }
    }
    // ────────────────────────────────────────────────────────────────

    // offsetForDrawing, drawCenterRect 등 원본 그대로 … (생략)

    // ────────────── ★ ③ refreshContent에 한 줄만 추가 ★ ──────────────
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        // 시작 시각을 기록
        if fadeStart == nil {
            fadeStart = CACurrentMediaTime()
        }
        
        var label : String
        var decimalPlaces = "0"
        var markerUnit = ""
        var markerString = ""

        // 날짜(타이틀)
        // label = chartView?.xAxis.valueFormatter?.stringForValue(entry.x, axis: chartView?.xAxis) ?? ""
        // 날짜(타이틀) — 줄바꿈(\n) 은 공백으로 대체
        if let raw = chartView?.xAxis.valueFormatter?.stringForValue(entry.x, axis: chartView!.xAxis) {
            let cleaned = raw.replacingOccurrences(of: "\n", with: " ")
            label = cleaned
        } else {
            label = ""
        }
        
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
        let titleSize = labelTitle?.size(withAttributes: _drawTitleAttributes) ?? CGSize.zero
        
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
            if object["marker"].exists() {
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
        var labelSize = labelns?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        if let raw = labelns as String?, raw.containsEmoji {
            labelSize.height = labelFont.lineHeight
        }
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

        arrowImage = arrowHidden ? nil : UIImage(named: "arrow_right_circle")

        if label.isEmpty {
            imageEmotion = nil
            
            if let _ = arrowImage {
                let arrowSize: CGFloat = 20   // draw에서 쓴 arrowSize와 맞춰야함
                let arrowPadding: CGFloat = 6
                _size.width = max(_size.width, arrowSize + arrowPadding)
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
            }

            if imageEmotion != nil {
                if let _ = arrowImage {
                    let arrowSize: CGFloat = 20   // draw에서 쓴 arrowSize와 맞춰야함
                    let arrowPadding: CGFloat = 6
                    _size.width = max(_size.width, arrowSize + arrowPadding + imageSize)
                } else {
                    _size.width = max(_size.width, _size.width + imageSize)
                }
            }
        }

        self.lastEntry = entry
    }
    
    open override func removeFromSuperview() {
        resetState()
        super.removeFromSuperview()
    }

    private func createOverlayButtonIfNeeded(_ entry: ChartDataEntry) {
        guard let chartView = chartView else { return }


        let overlayButton = OverlayMarkerButton(frame: lastBgRect)
        overlayButton.tag = 999
        overlayButton.backgroundColor = .clear  // 디버깅 시 색상 지정 가능
            
        // 디버그용
//        overlayButton.backgroundColor = .yellow
//        overlayButton.layer.borderColor = UIColor.red.cgColor
//        overlayButton.layer.borderWidth = 1.0

        overlayButton.clickHandler = { [weak chartView] in
            guard let chartView = chartView,
                let base = chartView.superview as? RNChartViewBase,
                let onMarkerClick = base.onMarkerClick else { 
                    self.resetState()
                    return 
                }

            let dict: [AnyHashable: Any] = [
                "x": entry.x,
                "y": entry.y,
                "data": EntryToDictionaryUtils.entryToDictionary(entry)
            ]
            
            onMarkerClick(dict)
            self.resetState()
        }

        chartView.addSubview(overlayButton)
    }
    
    func resetState() {
        fadeStart = nil
        lastEntry = nil
        lastBgRect = .zero
        
        chartView?.highlightValue(nil, callDelegate: false)
        chartView?.subviews
            .filter { $0.tag == 999 }
            .forEach { $0.removeFromSuperview() }
    }
}
