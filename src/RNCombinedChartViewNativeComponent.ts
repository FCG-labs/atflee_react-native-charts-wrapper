/**
 * Codegen JS spec for RNCombinedChart (Fabric).
 *
 * react-native-charts-wrapper의 모든 props는 NSDictionary/object 기반 dict-driven입니다.
 * Codegen에서 강타입으로 분해하는 것은 비현실적이므로 `UnsafeMixed`(any)로 통과시키고,
 * ObjC++ ComponentView wrapper에서 NSDictionary로 복원한 뒤 기존 Swift setter로 dispatch합니다.
 *
 * - 컴포넌트명은 Paper와 동일하게 'RNCombinedChart' 유지(JS lib/*.js의 requireNativeComponent 호환).
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
  // Base chart props
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

  // YAxis chart props
  yAxis?: UnsafeMixed;

  // BarLineChartBase props
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

  // CombinedChart specific
  drawOrder?: UnsafeMixed;
  drawValueAboveBar?: boolean;
  drawBarShadow?: boolean;
  highlightFullBarEnabled?: boolean;
  barRadius?: Double;

  // Events
  onSelect?: DirectEventHandler<ChartSelectEvent>;
  onChange?: DirectEventHandler<ChartChangeEvent>;
  onMarkerClick?: DirectEventHandler<ChartMarkerClickEvent>;
  onYaxisMinMaxChange?: DirectEventHandler<ChartYAxisMinMaxChangeEvent>;
}

export default codegenNativeComponent<NativeProps>(
  'RNCombinedChart',
) as HostComponent<NativeProps>;
