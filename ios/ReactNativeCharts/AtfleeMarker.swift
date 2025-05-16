//
//  AtfleeMarker.swift
//

import Foundation
//import Charts
import SwiftyJSON
import DGCharts

open class AtfleeMarker: MarkerView {
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
    
    
    func drawRect(context: CGContext, point: CGPoint) -> CGRect{
        let chart = super.chartView
        let width = _size.width
        let height = _size.height
        var pt = CGPoint(
            x: point.x - width/2,
            y: point.y - height - 10)
        
        // 이모티콘이 없을 경우 항상 차트위에 출력
        if imageEmotion == nil {
            pt = CGPoint(x: pt.x, y: 0)
        }
        
        let rect = CGRect(origin: pt, size: _size)
        drawCenterRect(context: context, rect: rect)
        
        let marginTop = 6.0
        
        return CGRect(
            origin: CGPoint(
                x: pt.x,
                y: pt.y + marginTop),
            size:_size)
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
        
        let rect = drawRect(context: context, point: point)
        
        UIGraphicsPushContext(context)
        
        // 타이틀
        if (labelTitle != nil && labelTitle!.length > 0) {
            labelTitle?.draw(in: rect, withAttributes: _drawTitleAttributes)
        }
        
        // 단위
        if (labelns != nil && labelns!.length > 0) {
            labelns?.draw(in: rect, withAttributes: _drawAttributes)
        }
        
        // 아이콘
        if imageEmotion != nil {
            let rc = CGRect(
                origin: CGPoint(
                    x: rect.origin.x + (rect.width - imageSize) / 2,
                    y: rect.origin.y + (rect.height - imageSize) / 2 + 8 // TODO: 8 대신 글자 height 계산
                ), size: CGSize(width: imageSize, height: imageSize))
            imageEmotion?.draw(in: rc)
        }
        
        UIGraphicsPopContext()
        
        context.restoreGState()
    }
    
    open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        var offset = super.offsetForDrawing(atPoint: point)
        let chart = self.chartView

        let width = self.bounds.size.width
        let height = self.bounds.size.height

        var newX = point.x + offset.x
        var newY = point.y + offset.y

        if newX < 0 {
            newX = 0
        }
        if let chart = chart, newX + width > chart.bounds.size.width {
            newX = chart.bounds.size.width - width
        }
        if newY < 0 {
            newY = 0
        }
        if let chart = chart, newY + height > chart.bounds.size.height {
            newY = chart.bounds.size.height - height
        }
        return CGPoint(x: newX - point.x, y: newY - point.y)
    }

    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
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

