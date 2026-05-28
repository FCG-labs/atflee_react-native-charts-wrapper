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
    /// y 위치를 무시하고 화면 상단에 고정할지 여부
    open var fixedOnTop: Bool = false

    open var fixedTopReservedOffset: CGFloat {
        if !fixedOnTop { return 0 }
        let fallbackTextHeight = max(max(titleFont?.lineHeight ?? 12.0, font?.lineHeight ?? 12.0), 18.0)
        let fallbackHeight = fallbackTextHeight + insets.top + insets.bottom
        let markerHeight = _size.height > 0 ? _size.height : fallbackHeight
        return 8.0 + markerHeight + 4.0
    }

    open var fixedTopBottom: CGFloat {
        if !fixedOnTop { return 0 }
        let fallbackTextHeight = max(max(titleFont?.lineHeight ?? 12.0, font?.lineHeight ?? 12.0), 18.0)
        let fallbackHeight = fallbackTextHeight + insets.top + insets.bottom
        let markerHeight = _size.height > 0 ? _size.height : fallbackHeight
        return 8.0 + markerHeight
    }

    
    // padding 8px (vertical) / 8px (horizontal)
    // 세로 padding을 2 → 8로 증가시켜 툴팁이 너무 얇아 보이지 않도록 함.
    fileprivate var insets = UIEdgeInsets(top: 8.0,left: 8.0,bottom: 8.0,right: 8.0)
    fileprivate var topInsets = UIEdgeInsets(top: 8.0,left: 8.0,bottom: 8.0,right: 8.0)

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

    
    private func adjustedMarkerPoint(for point: CGPoint, chartHeight: CGFloat) -> CGPoint {
        let iconExists = imageEmotion != nil
        let showAbove = fixedOnTop ? true : point.y > chartHeight * showAboveThreshold

        var markerPt = point
        let markerHeight = _size.height

        if fixedOnTop {
            markerPt.y = markerHeight
        } else if showAbove {
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

        let showMarkerAbove = fixedOnTop ? true : point.y > chartHeight * showAboveThreshold

        if fixedOnTop {
            markerPt.y = markerHeight
        } else if showMarkerAbove {
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
            // y\ucd95 \ub808\uc774\ube14\uc740 viewPortHandler.contentRect \ubc16(\ub9c8\uc9c4 \uc601\uc5ed)\uc5d0 \uadf8\ub824\uc9c0\ubbc0\ub85c
            // \ub9c8\ucee4 rect\ub294 contentRect \uc548\uc73c\ub85c clamp\ud574\uc57c y\uac12 \ub808\uc774\ube14\uc744 \uac00\ub9ac\uc9c0 \uc54a\uc74c.
            let cr = chart.viewPortHandler.contentRect
            let leftBound = cr.minX
            let rightBound = cr.maxX
            if pt.x < leftBound { pt.x = leftBound }
            if pt.x + _size.width > rightBound {
                pt.x = rightBound - _size.width
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
        // y축 레이블은 viewPortHandler.contentRect 바깥(마진)에 그려지므로
        // contentRect 안으로 clamp하여 y값 레이블을 가리지 않도록 함.
        if let chart = chartView {
            let cr = chart.viewPortHandler.contentRect
            let leftBound = cr.minX
            let rightBound = cr.maxX
            if pt.x < leftBound {
                pt.x = leftBound
            }
            if pt.x + width > rightBound {
                pt.x = rightBound - width
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
        // 4코너 모두 동일한 8pt — 디자인 결정(알약 형태 X). Android setCornerRadius(8dp)와 페어링.
        let roundRect = UIBezierPath(roundedRect: rect, byRoundingCorners:.allCorners,
                                     cornerRadii: CGSize(width: 8, height: 8))
        // markerColor prop 사용 (JS에서 markerColor로 전달)
        // 메인: #FFFFFF, 전체변화: #FAFAFA
        let bgColor = self.color ?? UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        context.setFillColor(bgColor.cgColor)
//        context.setShadow(offset: CGSize(width: 1.0, height: 4.0), blur: 7.5)
//        context.setBlendMode(.multiply)
        context.addPath(roundRect.cgPath)
        context.fillPath()
        context.restoreGState()
    }

    // ────────────── ★ ② draw(context:point:) 최소 패치 ★ ──────────────
    open override func draw(context: CGContext, point: CGPoint) {
        context.saveGState()
        context.resetClip()
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
        let showMarkerAbove = fixedOnTop ? true : point.y > chartHeight * showAboveThreshold

        context.setAlpha(alpha)
        if showMarkerAbove {
            context.translateBy(x: 0, y: -yRise)
        }

        let rect = drawRect(context: context, point: markerPt)
        self.lastBgRect = rect

        UIGraphicsPushContext(context)

        // 가로 배치: [날짜] gap [값+이모티콘] gap [화살표]
        let bgPadding: CGFloat = 8
        let paddedRect = rect.insetBy(dx: bgPadding, dy: bgPadding)
        let gapTitleValue: CGFloat = 6   // 날짜↔값 사이
        let gapValueArrow: CGFloat = 10  // 값↔화살표 사이
        let arrowSize: CGFloat = 18      // Figma: 18px
        let iconSize: CGFloat = CGFloat(imageSize)

        // 각 요소 크기 측정
        var titleSize = CGSize.zero
        if let title = labelTitle, title.length > 0 {
            titleSize = title.size(withAttributes: _drawTitleAttributes)
        }
        var valueSize = CGSize.zero
        if let lbl = labelns, lbl.length > 0 {
            valueSize = lbl.size(withAttributes: _drawAttributes)
        }

        // 세로 중앙 정렬 기준
        let maxTextH = max(titleSize.height, valueSize.height)
        let centerY = paddedRect.midY

        // ① 날짜 (좌측)
        var currX = paddedRect.minX
        if titleSize.width > 0 {
            let titleY = centerY - titleSize.height / 2
            let titleRect = CGRect(x: currX, y: titleY, width: titleSize.width, height: titleSize.height)
            labelTitle?.draw(in: titleRect, withAttributes: _drawTitleAttributes)
            currX += titleSize.width + gapTitleValue
        }

        // ② 값 + 이모티콘
        if valueSize.width > 0 {
            let valueY = centerY - valueSize.height / 2
            let valueRect = CGRect(x: currX, y: valueY, width: valueSize.width, height: valueSize.height)
            labelns?.draw(in: valueRect, withAttributes: _drawAttributes)
            currX += valueSize.width
        }

        if let img = imageEmotion {
            let iconY = centerY - iconSize / 2
            currX += 5  // 값↘이모티콘 간격
            let iconRect = CGRect(x: currX, y: iconY, width: iconSize, height: iconSize)
            img.draw(in: iconRect)
            currX += iconSize
        }

        // ③ 화살표 (우측)
        if let img = arrowImage {
            currX += gapValueArrow
            let arrowY = centerY - arrowSize / 2
            let arrowRect = CGRect(x: currX, y: arrowY, width: arrowSize, height: arrowSize)
            img.draw(in: arrowRect)
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
        // Figma: 날짜 Regular weight (Noto Sans KR Regular)
        if let notoRegular = UIFont(name: "NotoSansKR-Regular", size: 12.0) {
            _drawTitleAttributes[NSAttributedString.Key.font] = notoRegular
        } else {
            _drawTitleAttributes[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        }
        _drawTitleAttributes[NSAttributedString.Key.paragraphStyle] = _paragraphStyle
        _drawTitleAttributes[NSAttributedString.Key.foregroundColor] = UIColor(red: 0.263, green: 0.263, blue: 0.263, alpha: 1.0)  // #434343
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

        // 가로 배치: 줄바꿈 없이 값만 표시
        if let candleEntry = entry as? CandleChartDataEntry {
            label = candleEntry.close.description
        } else {
            if markerString.isEmpty {
                label = String(format:"%." + decimalPlaces + "f", entry.y) + markerUnit
            } else {
                label = markerString
            }
        }
        
        labelns = label as NSString
        
        _drawAttributes.removeAll()
        // Figma: caption_medium — letterSpacing -0.24px, center
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .center
        _drawAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
        _drawAttributes[NSAttributedString.Key.kern] = -0.24  // letterSpacing
        // Figma: 값 색상 #101010 (Grayscale_1000)
        _drawAttributes[NSAttributedString.Key.foregroundColor] = UIColor(red: 0.063, green: 0.063, blue: 0.063, alpha: 1.0)  // #101010

        let baseFont: UIFont = self.font ?? UIFont.systemFont(ofSize: 12.0)
        let fontSize = baseFont.pointSize

        // Figma: 값은 Medium weight (Noto Sans KR Medium)
        let labelFont: UIFont
        if textWeight == "bold" {
            labelFont = UIFont.boldSystemFont(ofSize: fontSize)
        } else {
            // Medium weight (weight=500)
            if let notoMedium = UIFont(name: "NotoSansKR-Medium", size: fontSize) {
                labelFont = notoMedium
            } else {
                labelFont = UIFont.systemFont(ofSize: fontSize, weight: .medium)
            }
        }

        _drawAttributes[.font] = labelFont

        // 전체 크기
        var labelSize = labelns?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        if let raw = labelns as String?, raw.containsEmoji {
            labelSize.height = labelFont.lineHeight
        }
        // 감정 이모티콘 코드 확인
        var emotionCode = ""
        if let object = entry.data as? JSON {
            if object["markerEmotion"].exists() {
                emotionCode = object["markerEmotion"].stringValue
            }
        }

        // Figma: 18x18 원형 화살표 SVG 직접 렌더링
        arrowImage = arrowHidden ? nil : Self.drawArrowCircleImage(size: 18)

        switch emotionCode {
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

        // width 계산: label, icon, arrow 포함
        let arrowExists = arrowImage != nil
        let iconExists = imageEmotion != nil
        let itemSpacing: CGFloat = 8
        let arrowSize: CGFloat = 18  // Figma: 18px
        let iconSize: CGFloat = CGFloat(imageSize)

        var itemWidths: [CGFloat] = []
        if labelSize.width > 0 { itemWidths.append(labelSize.width) }
        if iconExists { itemWidths.append(iconSize) }
        if arrowExists { itemWidths.append(arrowSize) }

        var bottomRowWidth: CGFloat = 0
        if !itemWidths.isEmpty {
            bottomRowWidth = itemWidths.reduce(0, +) + itemSpacing * CGFloat(itemWidths.count - 1)
        }

        // 가로 배치: 전체 너비 = 날짜 + gap + 값 + (이모티콘) + gap + 화살표
        let gapTitleValue: CGFloat = 6
        let gapValueArrow: CGFloat = 10
        var totalWidth: CGFloat = 0
        if titleSize.width > 0 { totalWidth += titleSize.width }
        if bottomRowWidth > 0 {
            if titleSize.width > 0 { totalWidth += gapTitleValue }
            totalWidth += bottomRowWidth
        }
        let rowHeight = max(titleSize.height, labelSize.height)
        _labelSize = CGSize(width: totalWidth, height: rowHeight)
        _size.width = _labelSize.width + self.insets.left + self.insets.right
        _size.height = _labelSize.height + self.insets.top + self.insets.bottom
        _size.width = max(minimumSize.width, _size.width)
        _size.height = max(minimumSize.height, _size.height)

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
    
    // Figma SVG: 18x18 원형 + 오른쪽 화살표
    // <rect width="18" height="18" rx="9" fill="#FAFAFA"/>
    // <path d="M7.5 12.75L11.25 9L7.5 5.25" stroke="#ABABAB" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    private static func drawArrowCircleImage(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            // 배경 원형
            let circle = UIBezierPath(roundedRect: rect, cornerRadius: size / 2)
            UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0).setFill()  // #FAFAFA
            circle.fill()
            // 화살표 패스
            let arrow = UIBezierPath()
            arrow.move(to: CGPoint(x: size * 7.5 / 18, y: size * 12.75 / 18))
            arrow.addLine(to: CGPoint(x: size * 11.25 / 18, y: size * 9.0 / 18))
            arrow.addLine(to: CGPoint(x: size * 7.5 / 18, y: size * 5.25 / 18))
            arrow.lineWidth = 1.5
            arrow.lineCapStyle = .round
            arrow.lineJoinStyle = .round
            UIColor(red: 0.671, green: 0.671, blue: 0.671, alpha: 1.0).setStroke()  // #ABABAB
            arrow.stroke()
        }
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
