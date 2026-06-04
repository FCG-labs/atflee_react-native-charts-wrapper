//
//  RNLineChartComponentView.mm
//  Fabric ComponentView wrapper for `RNLineChartView` (Swift).
//
//  Inherits BarLineChartBase only (no extra Line-specific bridge props).
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTViewComponentView.h>
#import <React/RCTConversions.h>
#import <react/renderer/components/RNChartsWrapperSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNChartsWrapperSpec/EventEmitters.h>
#import <react/renderer/components/RNChartsWrapperSpec/Props.h>
#import <react/renderer/components/RNChartsWrapperSpec/RCTComponentViewHelpers.h>

#import "RNChartsPropDispatch.h"
#if __has_include("ReactNativeCharts-Swift.h")
#import "ReactNativeCharts-Swift.h"
#elif __has_include("react_native_charts_wrapper-Swift.h")
#import "react_native_charts_wrapper-Swift.h"
#else
#import <ReactNativeCharts/ReactNativeCharts-Swift.h>
#endif

using namespace facebook::react;

@interface RNLineChartComponentView : RCTViewComponentView
@end

@implementation RNLineChartComponentView {
  RNLineChartView *_swiftView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNLineChartComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNLineChartProps>();
    _props = defaultProps;

    _swiftView = [[RNLineChartView alloc] initWithFrame:self.bounds];
    _swiftView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_swiftView];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (!CGRectEqualToRect(_swiftView.frame, self.bounds)) {
    _swiftView.frame = self.bounds;
  }
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<RNLineChartProps const>(props);
  const auto &oldP = oldProps
                         ? *std::static_pointer_cast<RNLineChartProps const>(oldProps)
                         : RNLineChartProps{};

  // ── ChartBase (dict) ──
  RNC_DISPATCH_DYNAMIC(data);
  RNC_DISPATCH_DYNAMIC(highlights);
  RNC_DISPATCH_DYNAMIC(legend);
  RNC_DISPATCH_DYNAMIC(chartDescription);
  RNC_DISPATCH_DYNAMIC(animation);
  RNC_DISPATCH_DYNAMIC(xAxis);
  RNC_DISPATCH_DYNAMIC(marker);

  // ── ChartBase (primitive) ──
  RNC_DISPATCH_NUMBER(chartBackgroundColor);
  RNC_DISPATCH_STRING(noDataText);
  RNC_DISPATCH_NUMBER(noDataTextColor);
  RNC_DISPATCH_BOOL(touchEnabled);
  RNC_DISPATCH_BOOL(highlightPerTapEnabled);
  RNC_DISPATCH_BOOL(dragDecelerationEnabled);
  RNC_DISPATCH_NUMBER(dragDecelerationFrictionCoef);
  RNC_DISPATCH_STRING(group);
  RNC_DISPATCH_STRING(identifier);
  RNC_DISPATCH_BOOL(syncX);
  RNC_DISPATCH_BOOL(syncY);
  RNC_DISPATCH_BOOL(landscapeOrientation);
  RNC_DISPATCH_NUMBER(eventThrottle);

  // ── YAxis chart ──
  RNC_DISPATCH_DYNAMIC(yAxis);

  // ── BarLineChartBase (dict) ──
  RNC_DISPATCH_DYNAMIC(visibleRange);
  RNC_DISPATCH_DYNAMIC(maxScale);
  RNC_DISPATCH_DYNAMIC(zoom);
  RNC_DISPATCH_DYNAMIC(viewPortOffsets);
  RNC_DISPATCH_DYNAMIC(extraOffsets);

  // ── BarLineChartBase (primitive) ──
  RNC_DISPATCH_BOOL(drawGridBackground);
  RNC_DISPATCH_NUMBER(maxHighlightDistance);
  RNC_DISPATCH_NUMBER(gridBackgroundColor);
  RNC_DISPATCH_BOOL(drawBorders);
  RNC_DISPATCH_NUMBER(borderColor);
  RNC_DISPATCH_NUMBER(borderWidth);
  RNC_DISPATCH_NUMBER(maxVisibleValueCount);
  RNC_DISPATCH_BOOL(autoScaleMinMaxEnabled);
  RNC_DISPATCH_BOOL(keepPositionOnRotation);
  RNC_DISPATCH_BOOL(scaleEnabled);
  RNC_DISPATCH_BOOL(dragEnabled);
  RNC_DISPATCH_BOOL(scaleXEnabled);
  RNC_DISPATCH_BOOL(scaleYEnabled);
  RNC_DISPATCH_BOOL(pinchZoom);
  RNC_DISPATCH_BOOL(highlightPerDragEnabled);
  RNC_DISPATCH_BOOL(doubleTapToZoomEnabled);

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> RNLineChartComponentViewCls(void)
{
  return RNLineChartComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
