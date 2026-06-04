//
//  RNRadarChartComponentView.mm
//  Fabric ComponentView wrapper for `RNRadarChartView` (Swift).
//
//  Inheritance: YAxisChartBase + Radar-specific. No BarLineChartBase.
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

@interface RNRadarChartComponentView : RCTViewComponentView
@end

@implementation RNRadarChartComponentView {
  RNRadarChartView *_swiftView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNRadarChartComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNRadarChartProps>();
    _props = defaultProps;

    _swiftView = [[RNRadarChartView alloc] initWithFrame:self.bounds];
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
  const auto &newProps = *std::static_pointer_cast<RNRadarChartProps const>(props);
  const auto &oldP = oldProps
                         ? *std::static_pointer_cast<RNRadarChartProps const>(oldProps)
                         : RNRadarChartProps{};

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

  // ── YAxis ──
  RNC_DISPATCH_DYNAMIC(yAxis);

  // ── Radar-specific ──
  RNC_DISPATCH_NUMBER(skipWebLineCount);
  RNC_DISPATCH_NUMBER(minOffset);
  RNC_DISPATCH_BOOL(drawWeb);
  RNC_DISPATCH_BOOL(rotationEnabled);
  RNC_DISPATCH_NUMBER(rotationAngle);
  RNC_DISPATCH_DYNAMIC(extraOffsets);
  RNC_DISPATCH_NUMBER(webLineWidth);
  RNC_DISPATCH_NUMBER(webLineWidthInner);
  RNC_DISPATCH_NUMBER(webAlpha);
  RNC_DISPATCH_NUMBER(webColor);
  RNC_DISPATCH_NUMBER(webColorInner);

  [super updateProps:props oldProps:oldProps];
}

@end

Class<RCTComponentViewProtocol> RNRadarChartComponentViewCls(void)
{
  return RNRadarChartComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
