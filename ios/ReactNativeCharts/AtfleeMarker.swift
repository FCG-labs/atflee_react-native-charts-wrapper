//
//  AtfleeMarker.swift
//

import Foundation
//import Charts
import SwiftyJSON
import DGCharts

open class AtfleeMarker: MarkerView {
    private var fadeStart: CFTimeInterval?
    private let fadeDuration: CFTimeInterval = 0.25
    
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
    fileprivate var _size: CGSize = CGSize()
    fileprivate var _paragraphStyle: NSMutableParagraphStyle?
    fileprivate var _drawAttributes = [NSAttributedString.Key: Any]()
    
    fileprivate var imageEmotion: UIImage? = nil
    fileprivate let imageSize = 16.0

    
    public init(color: UIColor, font: UIFont, textColor: UIColor, textAlign: NSTextAlignment) {
        super.init(frame: CGRect.zero);
        self.color = color
        self.font = font
        self.textColor = textColor
        
        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = textAlign
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
    
    
    open func drawRect(context: CGContext, point: CGPoint) -> CGRect {
        let width  = _size.width
        let height = _size.height
        
        // 포인트 위 중앙에 표시될 원래 pt
        var pt = CGPoint(x: point.x - width/2,
                         y: point.y - height - 10)
        
        // ② 엣지 보정: 좌/우/상 경계 안으로
        if let chart = chartView {
            if pt.x < 0 {
                pt.x = 8
            }
            if pt.x + width > chart.bounds.size.width {
                pt.x = chart.bounds.size.width - width - 8
            }
            if pt.y < 0 {
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

        let roundRect = UIBezierPath(roundedRect: rect, byRoundingCorners:.allCorners, cornerRadii: CGSize(width: 7.0, height: 7.0))
        context.setFillColor(UIColor.white.cgColor)
        context.setShadow(offset: CGSize(width: 1.0, height: 5.0), blur: 8.0)
//        context.setBlendMode(.multiply)
        context.addPath(roundRect.cgPath)
        context.fillPath()

        context.restoreGState()
    }

    
    
    open override func draw(context: CGContext, point: CGPoint) {
        context.saveGState()

        // ① Fade-in 진행률 계산
        var alpha: CGFloat = 1
        var progress: CGFloat = 1
        if let start = fadeStart {
            let elapsed = CACurrentMediaTime() - start
            progress = min(max(CGFloat(elapsed / fadeDuration), 0), 1)
            alpha = progress

            // fade 중이면 다음 프레임 요청
            if progress < 1, let chart = chartView {
                DispatchQueue.main.async { chart.setNeedsDisplay() }
            }
        }

        // ② Rise 효과: 초기엔 아래에서 시작해 점차 제자리로
        let maxYOffset: CGFloat = 20
        let yRise = maxYOffset * (1 - progress)

        // ③ 기존 배경 rect 계산 → Y축에 rise 반영
        var rect = drawRect(context: context, point: point)
        rect.origin.y += yRise

        // ④ 컨텍스트에 alpha 적용
        context.setAlpha(alpha)
        UIGraphicsPushContext(context)

        // ⑤ 기존 타이틀 텍스트
        if let title = labelTitle, title.length > 0 {
            title.draw(in: rect, withAttributes: _drawTitleAttributes)
        }

        // ⑥ 기존 단위 텍스트
        if let lbl = labelns, lbl.length > 0 {
            lbl.draw(in: rect, withAttributes: _drawAttributes)
        }

        // ⑦ 이모티콘 아이콘
        if let img = imageEmotion {
            let iconRect = CGRect(
                origin: CGPoint(
                    x: rect.origin.x + (rect.width - imageSize) / 2,
                    y: rect.origin.y + (rect.height - imageSize) / 2 + 8
                ),
                size: CGSize(width: imageSize, height: imageSize)
            )
            img.draw(in: iconRect)
        }

        UIGraphicsPopContext()
        context.restoreGState()
    }
    
    open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        let size = self.bounds.size
        // 기본 위치: 데이터 포인트 위에, 마커가 중심을 기준으로 배치
        return CGPoint(x: -size.width / 2, y: -size.height)
    }

    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        // 시작 시각을 기록
        fadeStart = CACurrentMediaTime()

        var label : String
        var decimalPlaces = "0"
        var markerUnit = ""
        var markerString = ""

        // 날짜(타이틀)
        label = chartView?.xAxis.valueFormatter?.stringForValue(entry.x, axis: chartView?.xAxis) ?? ""
        labelTitle = label as NSString

        _drawTitleAttributes.removeAll()
        _drawTitleAttributes[NSAttributedString.Key.font] = self.font
        _drawTitleAttributes[NSAttributedString.Key.paragraphStyle] = _paragraphStyle
        _drawTitleAttributes[NSAttributedString.Key.foregroundColor] = #colorLiteral(red: 0.9515632987, green: 0.4954123497, blue: 0.1712778509, alpha: 1)
        
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
        _drawAttributes[NSAttributedString.Key.font] = self.font
        _drawAttributes[NSAttributedString.Key.paragraphStyle] = _paragraphStyle
        _drawAttributes[NSAttributedString.Key.foregroundColor] = self.textColor

        // 전체 크기
        let titleSize = labelTitle?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        let labelSize = labelns?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        let maxWidth = max(titleSize.width, labelSize.width)
        let maxHeight = max(titleSize.height, labelSize.height)
        _labelSize = CGSize(width: maxWidth, height: maxHeight)
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
}

