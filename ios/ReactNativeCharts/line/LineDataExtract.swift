//  Created by xudong wu on 02/03/2017.
//  Copyright © 2017 wuxudong. All rights reserved.
//

import Foundation

import SwiftyJSON
import DGCharts
import UIKit

class LineDataExtract : DataExtract {
    override func createData() -> ChartData {
        return LineChartData();
    }

    override func createDataSet(_ entries: [ChartDataEntry], label: String) -> ChartDataSetProtocol {
        // densityStyle 이 없으면 LineChartDataSet 과 똑같이 동작한다(DensityStyledLineChartDataSet 주석).
        let dataSet = DensityStyledLineChartDataSet(entries: entries, label: label)
        dataSet.lineCapType = .round
        return dataSet
    }

    override func dataSetConfig(_ dataSet: ChartDataSetProtocol, config: JSON) {


        let lineDataSet = dataSet as! LineChartDataSet;

        ChartDataSetConfigUtils.commonConfig(lineDataSet, config: config);
        ChartDataSetConfigUtils.commonBarLineScatterCandleBubbleConfig(lineDataSet, config: config);
        ChartDataSetConfigUtils.commonLineScatterCandleRadarConfig(lineDataSet, config: config);
        ChartDataSetConfigUtils.commonLineRadarConfig(lineDataSet, config: config);

        // LineDataSet only config
        if config["circleRadius"].number != nil {
            lineDataSet.circleRadius = CGFloat(config["circleRadius"].numberValue)
        }


        if config["drawCircles"].bool != nil {
            lineDataSet.drawCirclesEnabled = config["drawCircles"].boolValue
        }


        if config["mode"].string != nil {
            lineDataSet.mode = BridgeUtils.parseLineChartMode(config["mode"].stringValue)
        }


        if config["drawCubicIntensity"].number != nil {
            lineDataSet.cubicIntensity = CGFloat(config["drawCubicIntensity"].numberValue);
        }


        if config["circleColor"].int != nil {
            lineDataSet.setCircleColor(RCTConvert.uiColor(config["circleColor"].intValue))
        }

        if config["circleColors"].array != nil {
            lineDataSet.circleColors = BridgeUtils.parseColors(config["circleColors"].arrayValue)
        }

        if config["circleHoleColor"].int != nil {
            lineDataSet.circleHoleColor = RCTConvert.uiColor(config["circleHoleColor"].intValue)
        }


        if config["drawCircleHole"].bool != nil {
            lineDataSet.drawCircleHoleEnabled = config["drawCircleHole"].boolValue
        }

        if config["dashedLine"].exists() {
            let dashedLine = config["dashedLine"]
            var lineLength = CGFloat(0);
            var spaceLength = CGFloat(0);
            var phase = CGFloat(0);

            if dashedLine["lineLength"].number != nil {
                lineLength = CGFloat(dashedLine["lineLength"].numberValue)
            }
            if dashedLine["spaceLength"].number != nil {
                spaceLength = CGFloat(dashedLine["spaceLength"].numberValue)
            }
            if dashedLine["phase"].number != nil {
                phase = CGFloat(dashedLine["phase"].numberValue)
            }

            lineDataSet.lineDashLengths = [lineLength, spaceLength]
            lineDataSet.lineDashPhase = phase
        }

        if config["fillFormatter"].exists() {
            let fillFormatter = config["fillFormatter"];
            var min = CGFloat(0);

            if fillFormatter["min"].number != nil {
                min = CGFloat(fillFormatter["min"].numberValue);
            }
            lineDataSet.fillFormatter = ConfigurableMinimumLinePositionFillFormatter(min);
        }

        if let styled = lineDataSet as? DensityStyledLineChartDataSet {
            styled.densityStyle = LineDataExtract.parseDensityStyle(config["densityStyle"])
        }
    }

    /// 보이는 점 개수에 따른 점·선 조형 — 빠진 값은 DensityStyle 기본값을 쓴다. 키가 없으면 끈다.
    static func parseDensityStyle(_ json: JSON) -> DensityStyledLineChartDataSet.DensityStyle? {
        guard json.dictionary != nil else { return nil }
        var style = DensityStyledLineChartDataSet.DensityStyle()
        if let v = json["referenceCount"].double { style.referenceCount = v }
        if let v = json["circleRadius"].double { style.circleRadius = v }
        if let v = json["lineWidth"].double { style.lineWidth = v }
        if let v = json["minLineWidth"].double { style.minLineWidth = v }
        if let v = json["lineWidthExponent"].double { style.lineWidthExponent = v }
        if let v = json["endsOnlyAbove"].double { style.endsOnlyAbove = v }
        if let v = json["endsOnlyReleaseAbove"].double { style.endsOnlyReleaseAbove = v }
        if let v = json["endCircleRadiusRatio"].double { style.endCircleRadiusRatio = v }
        if let v = json["minEndCircleRadius"].double { style.minEndCircleRadius = v }
        return style
    }

    override func createEntry(_ values: [JSON], index: Int) -> ChartDataEntry {
        var entry: ChartDataEntry;

        var x = Double(index);
        let value = values[index];

        if value.dictionary != nil {
            let dict = value;
            var y = Double(index);

            if dict["x"].double != nil {
                x = Double((dict["x"].doubleValue));
            }

            if dict["y"].number != nil {
                y = dict["y"].doubleValue;
            } else {
                fatalError("invalid data " + values.description);
            }

            if dict["icon"].exists() {
                let icon = dict["icon"]
                if icon["bundle"].dictionary != nil {
                    let bundle = icon["bundle"];

                    let uiImage = RCTConvert.uiImage(bundle.dictionaryObject);
                    let width = CGFloat(icon["width"].numberValue)/4;
                    let height = CGFloat(icon["height"].numberValue)/4;

                    if let image = uiImage {
                        let realIconImage = resizeImage(image: image, width: width, height: height);
                        entry = ChartDataEntry(x: x, y: dict["y"].doubleValue, icon: realIconImage);
                    } else {
                        entry = ChartDataEntry(x: x, y: dict["y"].doubleValue, icon: uiImage);
                    }


                } else {
                    entry = ChartDataEntry(x: x, y: dict["y"].doubleValue, data: dict as AnyObject?);
                }
            } else {
                entry = ChartDataEntry(x: x, y: dict["y"].doubleValue, data: dict as AnyObject?);
            }

        } else if value.double != nil {
            entry = ChartDataEntry(x: x, y: value.doubleValue);
        } else {
            fatalError("invalid data " + values.description);
        }

        return entry;
    }

    func resizeImage(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
      let targetSize = CGSize(width: width, height: height)
      let size = image.size

      let widthRatio  = targetSize.width  / size.width
      let heightRatio = targetSize.height / size.height

      // Figure out what our orientation is, and use that to form the rectangle
      var newSize: CGSize
      if(widthRatio > heightRatio) {
          newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
      } else {
          newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
      }

      // This is the rect that we've calculated out and this is what is actually used below
      let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

      // Actually do the resizing to the rect using the ImageContext stuff
      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      image.draw(in: rect)
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      return newImage!
    }
}
