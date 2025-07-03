#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "simplr-dark" asset catalog image resource.
static NSString * const ACImageNameSimplrDark AC_SWIFT_PRIVATE = @"simplr-dark";

/// The "simplr-light" asset catalog image resource.
static NSString * const ACImageNameSimplrLight AC_SWIFT_PRIVATE = @"simplr-light";

#undef AC_SWIFT_PRIVATE
