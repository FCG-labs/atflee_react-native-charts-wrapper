//
//  RNCombinedChartComponentView.mm
//  Fabric ComponentView wrapper for `RNCombinedChartView` (Swift).
//
//  ── Strategy (Tiger Style: Safety > Performance > DX) ──
//  • Keep the existing Swift `RNCombinedChartView` (UIView) untouched.
//  • This wrapper subclasses `RCTViewComponentView` and embeds the Swift view
//    as its only child, sized to bounds via autoresizingMask.
//  • `updateProps:oldProps:` diff-dispatches every prop to the Swift instance
//    via KVC (`setValue:forKey:`) using the macros in `RNChartsPropDispatch.h`.
//  • `folly::dynamic`-typed (`UnsafeMixed`) props are converted to `id`
//    (NSDictionary/NSArray) via `convertFollyDynamicToId`, matching the
//    existing `setXxx:(NSDictionary *)` Swift signatures byte-for-byte.
//

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTViewComponentView.h>
#import <React/RCTConversions.h>
#import <react/renderer/components/RNChartsWrapperSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNChartsWrapperSpec/EventEmitters.h>
#import <react/renderer/components/RNChartsWrapperSpec/Props.h>
#import <react/renderer/components/RNChartsWrapperSpec/RCTComponentViewHelpers.h>

#import "RNChartsPropDispatch.h"
#import <ReactNativeCharts/ReactNativeCharts-Swift.h>

using namespace facebook::react;

@interface RNCombinedChartComponentView : RCTViewComponentView
@end

@implementation RNCombinedChartComponentView {
  RNCombinedChartView *_swiftView;
}

#pragma mark - Component lifecycle

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNCombinedChartComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNCombinedChartProps>();
    _props = defaultProps;

    _swiftView = [[RNCombinedChartView alloc] initWithFrame:self.bounds];
    _swiftView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_swiftView];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  // autoresizingMask covers bounds change, but explicit assign is cheap insurance
  // when the parent layout uses non-standard frame propagation.
  if (!CGRectEqualToRect(_swiftView.frame, self.bounds)) {
    _swiftView.frame = self.bounds;
  }
}

#pragma mark - Prop dispatch

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &newProps = *std::static_pointer_cast<RNCombinedChartProps const>(props);
  const auto &oldP = oldProps
                         ? *std::static_pointer_cast<RNCombinedChartProps const>(oldProps)
                         : RNCombinedChartProps{};

  // ── ChartBase (dict-driven) ──
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

  // ── CombinedChart-specific ──
  RNC_DISPATCH_DYNAMIC(drawOrder);
  RNC_DISPATCH_BOOL(drawValueAboveBar);
  RNC_DISPATCH_BOOL(drawBarShadow);
  RNC_DISPATCH_BOOL(highlightFullBarEnabled);
  RNC_DISPATCH_NUMBER(barRadius);

  [super updateProps:props oldProps:oldProps];
}

@end

// Codegen-expected provider function (declared by RCTComponentViewHelpers.h).
Class<RCTComponentViewProtocol> RNCombinedChartComponentViewCls(void)
{
  return RNCombinedChartComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
