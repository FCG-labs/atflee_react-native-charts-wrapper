//
//  AtfleeMarker.swift
//

import Foundation
//import Charts
import SwiftyJSON
import DGCharts

open class AtfleeMarker: MarkerView {
    // MARK: – Fade‐in Animation
    private var fadeStart: CFTimeInterval?
    private let fadeDuration: CFTimeInterval = 0.25

    // MARK: – Appearance Properties
    open var color: UIColor?
    open var font: UIFont?
    open var textColor: UIColor?
    open var minimumSize = CGSize(width: 10, height: 10)

    // MARK: – Layout Internals
    fileprivate var insets = UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8)
    fileprivate var labelTitle: NSString?
    fileprivate var _drawTitleAttributes = [NSAttributedString.Key: Any]()
    fileprivate var labelns: NSString?
    fileprivate var _drawAttributes = [NSAttributedString.Key: Any]()
    fileprivate var _labelSize = CGSize.zero
    fileprivate var _size = CGSize.zero
    fileprivate var _paragraphStyle: NSMutableParagraphStyle?
    fileprivate var imageEmotion: UIImage?
    fileprivate let imageSize: CGFloat = 16.0

    // MARK: – Init
    public init(color: UIColor, font: UIFont, textColor: UIColor, textAlign: NSTextAlignment) {
        super.init(frame: .zero)
        self.color = color
        self.font = font
        self.textColor = textColor

        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = textAlign
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: – Background Drawing
    func drawCenterRect(context: CGContext, rect: CGRect) {
        context.saveGState()

        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners,
                                cornerRadii: CGSize(width: 7, height: 7))
        context.setFillColor(UIColor.white.cgColor)
        context.setShadow(offset: CGSize(width: 1, height: 5), blur: 8)
        context.addPath(path.cgPath)
        context.fillPath()

        context.restoreGState()
    }

    /// Calculates background rect at `point` plus edge‐of‐chart clamping and fade/rise effect
    open func drawRect(context: CGContext, point: CGPoint, fadeProgress: CGFloat) -> CGRect {
        let width = _size.width
        let height = _size.height
        let maxYOffset: CGFloat = 20
        let yRise = maxYOffset * (1 - fadeProgress)

        var pt = CGPoint(x: point.x - width/2, y: point.y - height - 10 + yRise)

        if let chart = chartView {
            if pt.x < 8 {
                pt.x = 8
            }
            if pt.x + width > chart.bounds.width - 8 {
                pt.x = chart.bounds.width - width - 8
            }
            if pt.y < 8 {
                pt.y = 8
            }
        }

        let bgRect = CGRect(origin: pt, size: _size)

        // fade-in 배경 알파 적용
        context.saveGState()
        context.setAlpha(fadeProgress)
        drawCenterRect(context: context, rect: bgRect)
        context.restoreGState()

        return bgRect
    }

    // MARK: – Main Drawing
    open override func draw(context: CGContext, point: CGPoint) {
        context.saveGState()

        // 1️⃣ Fade-in 진행률 계산
        var alpha: CGFloat = 1
        var progress: CGFloat = 1
        if let start = fadeStart {
            let elapsed = CACurrentMediaTime() - start
            progress = min(max(CGFloat(elapsed / fadeDuration), 0), 1)
            alpha = progress
            if progress < 1, let chart = chartView {
                DispatchQueue.main.async {
                    chart.setNeedsDisplay()
                    chart.layer.displayIfNeeded()
                }
            }
        }

        // 2️⃣ 배경 draw (rect + rise 포함)
        let rect = drawRect(context: context, point: point, fadeProgress: progress)

        // 3️⃣ 텍스트 색상 알파 반영
        if let baseColor = textColor {
            _drawTitleAttributes[.foregroundColor] = baseColor.withAlphaComponent(alpha)
            _drawAttributes[.foregroundColor] = baseColor.withAlphaComponent(alpha)
        }

        // 4️⃣ 텍스트/이미지 그리기
        context.setAlpha(alpha)
        UIGraphicsPushContext(context)

        if let title = labelTitle, title.length > 0 {
            title.draw(in: rect, withAttributes: _drawTitleAttributes)
        }

        if let lbl = labelns, lbl.length > 0 {
            lbl.draw(in: rect, withAttributes: _drawAttributes)
        }

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

    open override func offsetForDrawing(atPoint _: CGPoint) -> CGPoint {
        return CGPoint.zero
    }

    // MARK: – Refresh content
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        super.refreshContent(entry: entry, highlight: highlight)
        fadeStart = CACurrentMediaTime()

        // 타이틀
        let xAxis = chartView?.xAxis
        let title = xAxis?.valueFormatter?.stringForValue(entry.x, axis: xAxis) ?? ""
        labelTitle = title as NSString
        _drawTitleAttributes = [
            .font: font as Any,
            .paragraphStyle: _paragraphStyle as Any,
            .foregroundColor: textColor as Any
        ]

        // 데이터 단위
        var markerText = ""
        if let obj = entry.data as? JSON {
            markerText = obj["marker"]?.stringValue ?? ""
        }
        labelns = (markerText.isEmpty ? "\(entry.y)" : markerText) as NSString
        _drawAttributes = [
            .font: font as Any,
            .paragraphStyle: _paragraphStyle as Any,
            .foregroundColor: textColor as Any
        ]

        // 텍스트 크기 계산
        let tSize = labelTitle?.size(withAttributes: _drawTitleAttributes) ?? .zero
        let vSize = labelns?.size(withAttributes: _drawAttributes) ?? .zero
        let mw = max(tSize.width, vSize.width)
        let mh = max(tSize.height, vSize.height)
        _labelSize = CGSize(width: mw, height: mh)
        _size.width = max(minimumSize.width, mw + insets.left + insets.right)
        _size.height = max(minimumSize.height, mh + insets.top + insets.bottom)

        // 이모티콘 추가
        imageEmotion = nil
        if let obj = entry.data as? JSON, let emo = obj["markerEmotion"]?.stringValue {
            imageEmotion = UIImage(named: "emotion\(emo)")
            if imageEmotion != nil {
                _size.height += imageSize
            }
        }
    }
}