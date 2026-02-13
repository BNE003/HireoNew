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

#undef AC_SWIFT_PRIVATE
