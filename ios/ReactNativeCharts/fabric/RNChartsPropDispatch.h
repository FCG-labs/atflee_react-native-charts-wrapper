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

// folly::dynamic -> id (NSDictionary/NSArray/NSNumber/NSString/NSNull)
#define RNC_DISPATCH_DYNAMIC(KEY)                                              \
  do {                                                                         \
    if (newProps.KEY != oldP.KEY) {                                            \
      id _val = facebook::react::convertFollyDynamicToId(newProps.KEY);        \
      [_swiftView setValue:_val forKey:@ #KEY];                                \
    }                                                                          \
  } while (0)

// bool -> NSNumber
#define RNC_DISPATCH_BOOL(KEY)                                                 \
  do {                                                                         \
    if (newProps.KEY != oldP.KEY) {                                            \
      [_swiftView setValue:@(newProps.KEY) forKey:@ #KEY];                     \
    }                                                                          \
  } while (0)

// Int32 / Double / Float -> NSNumber
#define RNC_DISPATCH_NUMBER(KEY)                                               \
  do {                                                                         \
    if (newProps.KEY != oldP.KEY) {                                            \
      [_swiftView setValue:@(newProps.KEY) forKey:@ #KEY];                     \
    }                                                                          \
  } while (0)

// std::string -> NSString
#define RNC_DISPATCH_STRING(KEY)                                               \
  do {                                                                         \
    if (newProps.KEY != oldP.KEY) {                                            \
      NSString *_val = RCTNSStringFromString(newProps.KEY);                    \
      [_swiftView setValue:_val forKey:@ #KEY];                                \
    }                                                                          \
  } while (0)

#endif // RCT_NEW_ARCH_ENABLED
