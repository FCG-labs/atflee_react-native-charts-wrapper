//  Created by xudong wu on 24/02/2017.
//  Copyright wuxudong
//

import DGCharts
import SwiftyJSON

class RNCombinedChartView: RNBarLineChartViewBase {

    let _chart: CombinedChartView;
    let _dataExtract : CombinedDataExtract;

    private var barRadius: CGFloat = 0

    override var chart: CombinedChartView {
        return _chart
    }

    override var dataExtract: DataExtract {
        return _dataExtract
    }

    override init(frame: CoreGraphics.CGRect) {

        self._chart = CombinedChartView(frame: frame)
        self._dataExtract = CombinedDataExtract()

        super.init(frame: frame)

        self._chart.delegate = self
        self.addSubview(_chart)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDrawOrder(_ config: NSArray) {
        var array : [Int] = []
        for object in RCTConvert.nsStringArray(config) {
            array.append(BridgeUtils.parseDrawOrder(object).rawValue)
        }
        _chart.drawOrder = array
    }

    func setDrawValueAboveBar(_ enabled: Bool) {
        _chart.drawValueAboveBarEnabled = enabled
    }

    func setDrawBarShadow(_ enabled: Bool) {
        _chart.drawBarShadowEnabled = enabled
    }

    func setHighlightFullBarEnabled(_ enabled: Bool) {
        _chart.highlightFullBarEnabled = enabled
    }

    func setBarRadius(_ radius: NSNumber) {
        barRadius = CGFloat(truncating: radius)

        if barRadius > 0 {
            if let renderer = _chart.renderer as? RoundedCombinedChartRenderer {
                renderer.setRadius(barRadius)
            } else {
                _chart.renderer = RoundedCombinedChartRenderer(chart: _chart, animator: _chart.chartAnimator, viewPortHandler: _chart.viewPortHandler, barRadius: barRadius)
            }
        } else {
            if !(_chart.renderer is CombinedChartRenderer) {
                _chart.renderer = CombinedChartRenderer(chart: _chart, animator: _chart.chartAnimator, viewPortHandler: _chart.viewPortHandler)
            }
        }
        _chart.setNeedsDisplay()
    }

}
