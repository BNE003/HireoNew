#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "1" asset catalog image resource.
static NSString * const ACImageName1 AC_SWIFT_PRIVATE = @"1";

/// The "2" asset catalog image resource.
static NSString * const ACImageName2 AC_SWIFT_PRIVATE = @"2";

/// The "3" asset catalog image resource.
static NSString * const ACImageName3 AC_SWIFT_PRIVATE = @"3";

/// The "4" asset catalog image resource.
static NSString * const ACImageName4 AC_SWIFT_PRIVATE = @"4";

/// The "5" asset catalog image resource.
static NSString * const ACImageName5 AC_SWIFT_PRIVATE = @"5";

/// The "6" asset catalog image resource.
static NSString * const ACImageName6 AC_SWIFT_PRIVATE = @"6";

/// The "7" asset catalog image resource.
static NSString * const ACImageName7 AC_SWIFT_PRIVATE = @"7";

#undef AC_SWIFT_PRIVATE
