//
//  Created by wuxudong on 14/12/2017.
//  Copyright © 2017 wuxudong. All rights reserved.
//

import Foundation
import DGCharts

protocol RNBarLineChartBaseManager {
  var _bridge : RCTBridge? {get}
}

extension RNBarLineChartBaseManager {
  func _chartView(_ viewRegistry: [NSNumber : UIView]?, reactTag: NSNumber) -> RNBarLineChartViewBase? {
    return viewRegistry?[reactTag] as? RNBarLineChartViewBase;
  }

  func _moveViewToX(_ reactTag: NSNumber, xValue: NSNumber) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag), let chart = view.chart as? BarLineChartViewBase else { return }
      chart.moveViewToX(xValue.doubleValue);
    }
  }

  func _moveViewTo(_ reactTag: NSNumber, xValue: NSNumber, yValue: NSNumber, axisDependency: NSString) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag), let chart = view.chart as? BarLineChartViewBase else { return }
      chart.moveViewTo(xValue: xValue.doubleValue, yValue: yValue.doubleValue, axis: BridgeUtils.parseAxisDependency(axisDependency as String));
    }
  }

  func _moveViewToAnimated(_ reactTag: NSNumber, xValue: NSNumber, yValue: NSNumber, axisDependency: NSString, duration: NSNumber) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag), let chart = view.chart as? BarLineChartViewBase else { return }
      chart.moveViewToAnimated(xValue: xValue.doubleValue, yValue: yValue.doubleValue, axis: BridgeUtils.parseAxisDependency(axisDependency as String), duration: duration.doubleValue / 1000.0);
    }
  }

  func _centerViewTo(_ reactTag: NSNumber, xValue: NSNumber, yValue: NSNumber, axisDependency: NSString) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag), let chart = view.chart as? BarLineChartViewBase else { return }
      chart.centerViewTo(xValue: xValue.doubleValue, yValue: yValue.doubleValue, axis: BridgeUtils.parseAxisDependency(axisDependency as String));
    }
  }

  func _centerViewToAnimated(_ reactTag: NSNumber, xValue: NSNumber, yValue: NSNumber, axisDependency: NSString, duration: NSNumber) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag), let chart = view.chart as? BarLineChartViewBase else { return }
      chart.centerViewToAnimated(xValue: xValue.doubleValue, yValue: yValue.doubleValue, axis: BridgeUtils.parseAxisDependency(axisDependency as String), duration: duration.doubleValue / 1000.0);
    }
  }

  func _fitScreen(_ reactTag: NSNumber) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag), let chart = view.chart as? BarLineChartViewBase else { return }
      chart.fitScreen();
    }
  }

  func _highlights(_ reactTag: NSNumber, config: NSArray) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag), let chart = view.chart as? BarLineChartViewBase else { return }
      chart.highlightValues(HighlightUtils.getHighlights(config));
    }
  }

  func _setDataAndLockIndex(_ reactTag: NSNumber, data: NSDictionary) {
    _bridge?.uiManager.addUIBlock { (uiManager: RCTUIManager?, viewRegistry:[NSNumber : UIView]?) in
      guard let view = self._chartView(viewRegistry, reactTag: reactTag) else { return }
      view.setDataAndLockIndex(data);
    }
  }
}



