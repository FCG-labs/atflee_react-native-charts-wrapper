//
//  RNScatterChartComponentView.mm
//  Fabric ComponentView wrapper for `RNScatterChartView` (Swift).
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

@interface RNScatterChartComponentView : RCTViewComponentView
@end

@implementation RNScatterChartComponentView {
  RNScatterChartView *_swiftView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNScatterChartComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNScatterChartProps>();
    _props = defaultProps;

    _swiftView = [[RNScatterChartView alloc] initWithFrame:self.bounds];
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
  const auto &newProps = *std::static_pointer_cast<RNScatterChartProps const>(props);
  const auto &oldP = oldProps
                         ? *std::static_pointer_cast<RNScatterChartProps const>(oldProps)
                         : RNScatterChartProps{};

  // ── ChartBase ──
  RNC_DISPATCH_DYNAMIC(data);
  RNC_DISPATCH_DYNAMIC(highlights);
  RNC_DISPATCH_DYNAMIC(legend);
  RNC_DISPATCH_DYNAMIC(chartDescription);
  RNC_DISPATCH_DYNAMIC(animation);
  RNC_DISPATCH_DYNAMIC(xAxis);
  RNC_DISPATCH_DYNAMIC(marker);
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

  // ── YAxis ──
  RNC_DISPATCH_DYNAMIC(yAxis);

  // ── BarLineChartBase ──
  RNC_DISPATCH_DYNAMIC(visibleRange);
  RNC_DISPATCH_DYNAMIC(maxScale);
  RNC_DISPATCH_DYNAMIC(zoom);
  RNC_DISPATCH_DYNAMIC(viewPortOffsets);
  RNC_DISPATCH_DYNAMIC(extraOffsets);
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

Class<RCTComponentViewProtocol> RNScatterChartComponentViewCls(void)
{
  return RNScatterChartComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
