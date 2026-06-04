/**
 * Codegen JS spec for RNHorizontalBarChart (Fabric).
 *
 * Inheritance: BarLineChartBase + HorizontalBar-specific props
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

  drawGridBackground?: boolean;
  maxHighlightDistance?: Double;
  gridBackgroundColor?: Int32;
  drawBorders?: boolean;
  borderColor?: Int32;
  borderWidth?: Double;
  maxVisibleValueCount?: Double;
  visibleRange?: UnsafeMixed;
  maxScale?: UnsafeMixed;
  autoScaleMinMaxEnabled?: boolean;
  keepPositionOnRotation?: boolean;
  scaleEnabled?: boolean;
  dragEnabled?: boolean;
  scaleXEnabled?: boolean;
  scaleYEnabled?: boolean;
  pinchZoom?: boolean;
  highlightPerDragEnabled?: boolean;
  doubleTapToZoomEnabled?: boolean;
  zoom?: UnsafeMixed;
  viewPortOffsets?: UnsafeMixed;
  extraOffsets?: UnsafeMixed;

  drawValueAboveBar?: boolean;
  drawBarShadow?: boolean;
  barRadius?: Double;

  onSelect?: DirectEventHandler<ChartEvent>;
  onChange?: DirectEventHandler<ChartEvent>;
  onMarkerClick?: DirectEventHandler<ChartEvent>;
  onYaxisMinMaxChange?: DirectEventHandler<ChartEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'RNHorizontalBarChart',
) as HostComponent<NativeProps>;
