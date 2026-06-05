/**
 * Codegen JS spec for RNBarChart (Fabric).
 *
 * Inheritance: BarLineChartBase + Bar-specific props
 */

import type { HostComponent, ViewProps } from 'react-native';
import type {
  DirectEventHandler,
  Int32,
  Double,
  WithDefault,
  UnsafeMixed,
} from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

type ChartSelectEvent = Readonly<{
  x?: Double;
  y?: Double;
  data?: UnsafeMixed;
}>;

type ChartChangeEvent = Readonly<{
  action: string;
  left?: Double;
  right?: Double;
  top?: Double;
  bottom?: Double;
  scaleX?: Double;
  scaleY?: Double;
  centerX?: Double;
  centerY?: Double;
}>;

type ChartMarkerClickEvent = Readonly<{
  x?: Double;
  y?: Double;
  data?: UnsafeMixed;
}>;

type ChartYAxisMinMaxChangeEvent = Readonly<{
  minY?: Double;
  maxY?: Double;
}>;

export interface NativeProps extends ViewProps {
  data?: UnsafeMixed;
  highlights?: UnsafeMixed;
  legend?: UnsafeMixed;
  chartBackgroundColor?: Int32;
  chartDescription?: UnsafeMixed;
  noDataText?: string;
  noDataTextColor?: Int32;
  touchEnabled?: WithDefault<boolean, true>;
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
  highlightFullBarEnabled?: boolean;
  barRadius?: Double;

  onSelect?: DirectEventHandler<ChartSelectEvent>;
  onChange?: DirectEventHandler<ChartChangeEvent>;
  onMarkerClick?: DirectEventHandler<ChartMarkerClickEvent>;
  onYaxisMinMaxChange?: DirectEventHandler<ChartYAxisMinMaxChangeEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'RNBarChart',
) as HostComponent<NativeProps>;
