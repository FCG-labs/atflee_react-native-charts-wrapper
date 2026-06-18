//
//  RNChartsPropDispatch.h
//  Common Fabric ComponentView -> Swift ViewClass KVC dispatch macros.
//
//  Each ComponentView wraps an existing Swift `RNXxxChartView` (UIView subclass,
//  @objcMembers via inheritance from `RNChartViewBase`). All setters follow the
//  pattern `func setXxx(_:)` which becomes `setXxx:` ObjC selector and is
//  reachable via KVC `setValue:forKey:`. These macros automate
//  `newProps -> Swift instance` dispatch with old/new diff.
//

#pragma once

#ifdef RCT_NEW_ARCH_ENABLED

#import <React/RCTConversions.h>
#import <objc/message.h>

static inline void RNCInvokeSelectorWithoutObject(UIView *view, SEL selector)
{
  if ([view respondsToSelector:selector]) {
    ((void (*)(id, SEL))objc_msgSend)(view, selector);
  }
}

static inline void RNCInvokeReactSetFrame(UIView *view, CGRect frame)
{
  SEL selector = @selector(reactSetFrame:);
  if ([view respondsToSelector:selector]) {
    ((void (*)(id, SEL, CGRect))objc_msgSend)(view, selector, frame);
  } else {
    view.frame = frame;
  }
}

#define RNC_FINISH_BARLINE_UPDATE_PROPS()                                      \
  do {                                                                         \
    [super updateProps:props oldProps:oldProps];                                 \
    RNCInvokeSelectorWithoutObject(_swiftView, @selector(onAfterDataSetChanged)); \
  } while (0)

static inline UIView *RNCInstantiateView(NSString *className, CGRect frame)
{
  NSArray<NSString *> *candidateClassNames = @[
    className,
    [@"ReactNativeCharts." stringByAppendingString:className],
    [@"react_native_charts_wrapper." stringByAppendingString:className],
  ];

  Class swiftViewClass = Nil;
  for (NSString *candidateClassName in candidateClassNames) {
    swiftViewClass = NSClassFromString(candidateClassName);
    if (swiftViewClass != Nil) {
      break;
    }
  }

  NSCAssert(swiftViewClass != Nil, @"Unable to resolve chart Swift class: %@", className);
  UIView *view = [[swiftViewClass alloc] initWithFrame:frame];
  NSCAssert([view isKindOfClass:[UIView class]], @"Resolved class is not a UIView: %@", className);
  return view;
}

static inline id RNCConvertFollyDynamicToId(const folly::dynamic &dyn)
{
  switch (dyn.type()) {
    case folly::dynamic::NULLT:
      return (id)kCFNull;
    case folly::dynamic::BOOL:
      return dyn.getBool() ? @YES : @NO;
    case folly::dynamic::INT64:
      return @(dyn.getInt());
    case folly::dynamic::DOUBLE:
      return @(dyn.getDouble());
    case folly::dynamic::STRING:
      return [[NSString alloc] initWithBytes:dyn.c_str() length:dyn.size() encoding:NSUTF8StringEncoding];
    case folly::dynamic::ARRAY: {
      NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:dyn.size()];
      for (const auto &elem : dyn) {
        id value = RNCConvertFollyDynamicToId(elem);
        if (value) {
          [array addObject:value];
        }
      }
      return array;
    }
    case folly::dynamic::OBJECT: {
      NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:dyn.size()];
      for (const auto &elem : dyn.items()) {
        id key = RNCConvertFollyDynamicToId(elem.first);
        id value = RNCConvertFollyDynamicToId(elem.second);
        if (key && value) {
          dict[key] = value;
        }
      }
      return dict;
    }
  }
}

// folly::dynamic -> id (NSDictionary/NSArray/NSNumber/NSString/NSNull)
#define RNC_DISPATCH_DYNAMIC(KEY)                                              \
  do {                                                                         \
    if (oldPropsPtr == nullptr || newProps.KEY != oldPropsPtr->KEY) {          \
      id _val = RNCConvertFollyDynamicToId(newProps.KEY);                      \
      [_swiftView setValue:_val forKey:@ #KEY];                                \
    }                                                                          \
  } while (0)

// bool -> NSNumber
#define RNC_DISPATCH_BOOL(KEY)                                                 \
  do {                                                                         \
    if (oldPropsPtr == nullptr || newProps.KEY != oldPropsPtr->KEY) {          \
      [_swiftView setValue:@(newProps.KEY) forKey:@ #KEY];                     \
    }                                                                          \
  } while (0)

// Int32 / Double / Float -> NSNumber
#define RNC_DISPATCH_NUMBER(KEY)                                               \
  do {                                                                         \
    if (oldPropsPtr == nullptr || newProps.KEY != oldPropsPtr->KEY) {          \
      [_swiftView setValue:@(newProps.KEY) forKey:@ #KEY];                     \
    }                                                                          \
  } while (0)

// std::string -> NSString
#define RNC_DISPATCH_STRING(KEY)                                               \
  do {                                                                         \
    if (oldPropsPtr == nullptr || newProps.KEY != oldPropsPtr->KEY) {          \
      NSString *_val = RCTNSStringFromString(newProps.KEY);                    \
      [_swiftView setValue:_val forKey:@ #KEY];                                \
    }                                                                          \
  } while (0)

#endif // RCT_NEW_ARCH_ENABLED
