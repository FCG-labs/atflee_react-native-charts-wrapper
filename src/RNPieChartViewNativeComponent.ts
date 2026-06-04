/**
 * Codegen JS spec for RNPieChart (Fabric).
 *
 * Inheritance: ChartBase (no Y axis, no BarLine) + Pie-specific
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

  drawEntryLabels?: boolean;
  usePercentValues?: boolean;
  centerText?: string;
  styledCenterText?: UnsafeMixed;
  centerTextRadiusPercent?: Double;
  holeRadius?: Double;
  holeColor?: Int32;
  transparentCircleRadius?: Double;
  transparentCircleColor?: Int32;
  entryLabelColor?: Int32;
  entryLabelFontFamily?: string;
  entryLabelTextSize?: Double;
  extraOffsets?: UnsafeMixed;
  maxAngle?: Double;
  minOffset?: Double;
  rotationEnabled?: boolean;
  rotationAngle?: Double;

  onSelect?: DirectEventHandler<ChartEvent>;
  onChange?: DirectEventHandler<ChartEvent>;
  onMarkerClick?: DirectEventHandler<ChartEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'RNPieChart',
) as HostComponent<NativeProps>;
