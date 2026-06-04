//
//  RNPieChartComponentView.mm
//  Fabric ComponentView wrapper for `RNPieChartView` (Swift).
//
//  Inheritance: ChartBase only. No YAxis. No BarLineChartBase.
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

@interface RNPieChartComponentView : RCTViewComponentView
@end

@implementation RNPieChartComponentView {
  RNPieChartView *_swiftView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNPieChartComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNPieChartProps>();
    _props = defaultProps;

    _swiftView = [[RNPieChartView alloc] initWithFrame:self.bounds];
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
  const auto &newProps = *std::static_pointer_cast<RNPieChartProps const>(props);
  const auto &oldP = oldProps
                         ? *std::static_pointer_cast<RNPieChartProps const>(oldProps)
                         : RNPieChartProps{};

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

  // ── Pie-specific ──
  RNC_DISPATCH_BOOL(drawEntryLabels);
  RNC_DISPATCH_BOOL(usePercentValues);
  RNC_DISPATCH_STRING(centerText);
  RNC_DISPATCH_DYNAMIC(styledCenterText);
  RNC_DISPATCH_NUMBER(centerTextRadiusPercent);
  RNC_DISPATCH_NUMBER(holeRadius);
  RNC_DISPATCH_NUMBER(holeColor);
  RNC_DISPATCH_NUMBER(transparentCircleRadius);
  RNC_DISPATCH_NUMBER(transparentCircleColor);
  RNC_DISPATCH_NUMBER(entryLabelColor);
  RNC_DISPATCH_STRING(entryLabelFontFamily);
  RNC_DISPATCH_NUMBER(entryLabelTextSize);
  RNC_DISPATCH_DYNAMIC(extraOffsets);
  RNC_DISPATCH_NUMBER(maxAngle);
  RNC_DISPATCH_NUMBER(minOffset);
  RNC_DISPATCH_BOOL(rotationEnabled);
  RNC_DISPATCH_NUMBER(rotationAngle);

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> RNPieChartComponentViewCls(void)
{
  return RNPieChartComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
