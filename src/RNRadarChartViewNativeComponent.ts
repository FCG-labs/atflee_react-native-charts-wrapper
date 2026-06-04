/**
 * Codegen JS spec for RNRadarChart (Fabric).
 *
 * Inheritance: YAxisChartBase + Radar-specific
 */

import type { HostComponent, ViewProps } from 'react-native';
import type {
  DirectEventHandler,
  Int32,
  Double,
  UnsafeMixed,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

type ChartEvent = Readonly<{
  action: string;
  x?: Double;
  y?: Double;
  entry?: UnsafeMixed;
  data?: UnsafeMixed;
}>;

export interface NativeProps extends ViewProps {
  data?: UnsafeMixed;
  highlights?: UnsafeMixed;
  legend?: UnsafeMixed;
  chartBackgroundColor?: Int32;
  chartDescription?: UnsafeMixed;
  noDataText?: string;
  noDataTextColor?: Int32;
  touchEnabled?: boolean;
  highlightPerTapEnabled?: boolean;
  dragDecelerationEnabled?: boolean;
  dragDecelerationFrictionCoef?: Double;
  animation?: UnsafeMixed;
  xAxis?: UnsafeMixed;
  marker?: UnsafeMixed;
  group?: string;
  identifier?: string;
  syncX?: boolean;
  syncY?: boolean;
  landscapeOrientation?: boolean;
  eventThrottle?: Int32;

  yAxis?: UnsafeMixed;

  skipWebLineCount?: Int32;
  minOffset?: Double;
  drawWeb?: boolean;
  rotationEnabled?: boolean;
  rotationAngle?: Double;
  extraOffsets?: UnsafeMixed;
  webLineWidth?: Double;
  webLineWidthInner?: Double;
  webAlpha?: Double;
  webColor?: Int32;
  webColorInner?: Int32;

  onSelect?: DirectEventHandler<ChartEvent>;
  onChange?: DirectEventHandler<ChartEvent>;
  onMarkerClick?: DirectEventHandler<ChartEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'RNRadarChart',
) as HostComponent<NativeProps>;
