//
//  RNBarChartComponentView.mm
//  Fabric ComponentView wrapper for `RNBarChartView` (Swift).
//
//  Inheritance chain (Swift): RNBarChartView -> RNBarChartViewBase -> RNBarLineChartViewBase
//    -> RNYAxisChartViewBase -> RNChartViewBase (UIView, @objcMembers)
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTViewComponentView.h>
#import <React/RCTConversions.h>
#import <react/renderer/components/RNChartsWrapperSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNChartsWrapperSpec/EventEmitters.h>
#import <react/renderer/components/RNChartsWrapperSpec/Props.h>
#import <react/renderer/components/RNChartsWrapperSpec/RCTComponentViewHelpers.h>

#import "RNChartsPropDispatch.h"

using namespace facebook::react;

@interface RNBarChartComponentView : RCTViewComponentView
@end

@implementation RNBarChartComponentView {
  UIView *_swiftView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNBarChartComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNBarChartProps>();
    _props = defaultProps;

    _swiftView = RNCInstantiateView(@"RNBarChartView", self.bounds);
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
  const auto &newProps = *std::static_pointer_cast<RNBarChartProps const>(props);
  const auto *oldPropsPtr = oldProps
                                ? std::static_pointer_cast<RNBarChartProps const>(oldProps).get()
                                : nullptr;

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

  // ── Bar-specific ──
  RNC_DISPATCH_BOOL(drawValueAboveBar);
  RNC_DISPATCH_BOOL(drawBarShadow);
  RNC_DISPATCH_BOOL(highlightFullBarEnabled);
  RNC_DISPATCH_NUMBER(barRadius);

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> RNBarChartComponentViewCls(void)
{
  return RNBarChartComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
