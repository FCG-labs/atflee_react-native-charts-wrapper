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
#import <objc/message.h>

#import "RNChartsPropDispatch.h"

using namespace facebook::react;

static inline std::string RNCChartEventString(NSDictionary *event, NSString *key)
{
  id value = event[key];
  if (![value isKindOfClass:[NSString class]]) {
    return "";
  }

  return std::string([(NSString *)value UTF8String]);
}

static inline double RNCChartEventDouble(NSDictionary *event, NSString *key)
{
  id value = event[key];
  return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 0;
}

static inline folly::dynamic RNCConvertIdToFollyDynamic(id value)
{
  if (value == nil || value == (id)kCFNull) {
    return nullptr;
  }

  if ([value isKindOfClass:[NSString class]]) {
    return std::string([(NSString *)value UTF8String]);
  }

  if ([value isKindOfClass:[NSNumber class]]) {
    NSNumber *number = (NSNumber *)value;
    if (CFGetTypeID((__bridge CFTypeRef)number) == CFBooleanGetTypeID()) {
      return (bool)number.boolValue;
    }

    return number.doubleValue;
  }

  if ([value isKindOfClass:[NSArray class]]) {
    folly::dynamic array = folly::dynamic::array;
    for (id item in (NSArray *)value) {
      array.push_back(RNCConvertIdToFollyDynamic(item));
    }
    return array;
  }

  if ([value isKindOfClass:[NSDictionary class]]) {
    __block folly::dynamic object = folly::dynamic::object();
    [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      NSString *stringKey = [key isKindOfClass:[NSString class]] ? (NSString *)key : [key description];
      object[std::string([stringKey UTF8String])] = RNCConvertIdToFollyDynamic(obj);
    }];
    return object;
  }

  return nullptr;
}

static inline folly::dynamic RNCChartEventDynamic(NSDictionary *event, NSString *key)
{
  id value = event[key];
  return RNCConvertIdToFollyDynamic(value ?: (id)kCFNull);
}

static inline void RNCInvokeSelectorWithObject(UIView *view, SEL selector, id arg)
{
  if ([view respondsToSelector:selector]) {
    ((void (*)(id, SEL, id))objc_msgSend)(view, selector, arg);
  }
}

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
    RNCInvokeReactSetFrame(_swiftView, self.bounds);
  }
}

- (void)updateEventEmitter:(const EventEmitter::Shared &)eventEmitter
{
  [super updateEventEmitter:eventEmitter];

  if (!_swiftView) {
    return;
  }

  if (!eventEmitter) {
    [_swiftView setValue:nil forKey:@"onSelect"];
    [_swiftView setValue:nil forKey:@"onChange"];
    [_swiftView setValue:nil forKey:@"onMarkerClick"];
    [_swiftView setValue:nil forKey:@"onYaxisMinMaxChange"];
    return;
  }

  auto chartEventEmitter = std::static_pointer_cast<const RNBarChartEventEmitter>(eventEmitter);

  [_swiftView setValue:[^(NSDictionary *event) {
    NSDictionary *payloadEvent = event ?: @{};
    RNBarChartEventEmitter::OnSelect payload = {
      .x = RNCChartEventDouble(payloadEvent, @"x"),
      .y = RNCChartEventDouble(payloadEvent, @"y"),
      .data = RNCChartEventDynamic(payloadEvent, @"data"),
    };
    chartEventEmitter->onSelect(payload);
  } copy] forKey:@"onSelect"];

  [_swiftView setValue:[^(NSDictionary *event) {
    NSDictionary *payloadEvent = event ?: @{};
    RNBarChartEventEmitter::OnChange payload = {
      .action = RNCChartEventString(payloadEvent, @"action"),
      .left = RNCChartEventDouble(payloadEvent, @"left"),
      .right = RNCChartEventDouble(payloadEvent, @"right"),
      .top = RNCChartEventDouble(payloadEvent, @"top"),
      .bottom = RNCChartEventDouble(payloadEvent, @"bottom"),
      .scaleX = RNCChartEventDouble(payloadEvent, @"scaleX"),
      .scaleY = RNCChartEventDouble(payloadEvent, @"scaleY"),
      .centerX = RNCChartEventDouble(payloadEvent, @"centerX"),
      .centerY = RNCChartEventDouble(payloadEvent, @"centerY"),
    };
    chartEventEmitter->onChange(payload);
  } copy] forKey:@"onChange"];

  [_swiftView setValue:[^(NSDictionary *event) {
    NSDictionary *payloadEvent = event ?: @{};
    RNBarChartEventEmitter::OnMarkerClick payload = {
      .x = RNCChartEventDouble(payloadEvent, @"x"),
      .y = RNCChartEventDouble(payloadEvent, @"y"),
      .data = RNCChartEventDynamic(payloadEvent, @"data"),
    };
    chartEventEmitter->onMarkerClick(payload);
  } copy] forKey:@"onMarkerClick"];

  [_swiftView setValue:[^(NSDictionary *event) {
    NSDictionary *payloadEvent = event ?: @{};
    RNBarChartEventEmitter::OnYaxisMinMaxChange payload = {
      .minY = RNCChartEventDouble(payloadEvent, @"minY"),
      .maxY = RNCChartEventDouble(payloadEvent, @"maxY"),
    };
    chartEventEmitter->onYaxisMinMaxChange(payload);
  } copy] forKey:@"onYaxisMinMaxChange"];

  RNCInvokeSelectorWithoutObject(_swiftView, @selector(emitChartLoadCompleteIfReadyFromObjC));
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args
{
  if ([commandName isEqualToString:@"moveViewToX"] && args.count >= 1) {
    RNCInvokeSelectorWithObject(_swiftView, @selector(fabricMoveViewToX:), args[0]);
    return;
  }

  if ([commandName isEqualToString:@"moveViewTo"] && args.count >= 3) {
    NSDictionary *commandArgs = @{
      @"xValue": args[0],
      @"yValue": args[1],
      @"axisDependency": args[2],
    };
    RNCInvokeSelectorWithObject(_swiftView, @selector(fabricMoveViewTo:), commandArgs);
    return;
  }

  if ([commandName isEqualToString:@"moveViewToAnimated"] && args.count >= 4) {
    NSDictionary *commandArgs = @{
      @"xValue": args[0],
      @"yValue": args[1],
      @"axisDependency": args[2],
      @"duration": args[3],
    };
    RNCInvokeSelectorWithObject(_swiftView, @selector(fabricMoveViewToAnimated:), commandArgs);
    return;
  }

  if ([commandName isEqualToString:@"centerViewTo"] && args.count >= 3) {
    NSDictionary *commandArgs = @{
      @"xValue": args[0],
      @"yValue": args[1],
      @"axisDependency": args[2],
    };
    RNCInvokeSelectorWithObject(_swiftView, @selector(fabricCenterViewTo:), commandArgs);
    return;
  }

  if ([commandName isEqualToString:@"centerViewToAnimated"] && args.count >= 4) {
    NSDictionary *commandArgs = @{
      @"xValue": args[0],
      @"yValue": args[1],
      @"axisDependency": args[2],
      @"duration": args[3],
    };
    RNCInvokeSelectorWithObject(_swiftView, @selector(fabricCenterViewToAnimated:), commandArgs);
    return;
  }

  if ([commandName isEqualToString:@"fitScreen"]) {
    RNCInvokeSelectorWithoutObject(_swiftView, @selector(fabricFitScreen));
    return;
  }

  if ([commandName isEqualToString:@"highlights"] && args.count >= 1) {
    RNCInvokeSelectorWithObject(_swiftView, @selector(fabricHighlights:), args[0]);
    return;
  }

  if ([commandName isEqualToString:@"setDataAndLockIndex"] && args.count >= 1) {
    RNCInvokeSelectorWithObject(_swiftView, @selector(fabricSetDataAndLockIndex:), args[0]);
    return;
  }

  [super handleCommand:commandName args:args];
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
  RNCInvokeSelectorWithoutObject(_swiftView, @selector(onAfterDataSetChanged));
}

@end

Class<RCTComponentViewProtocol> RNBarChartComponentViewCls(void)
{
  return RNBarChartComponentView.class;
}

#endif // RCT_NEW_ARCH_ENABLED
