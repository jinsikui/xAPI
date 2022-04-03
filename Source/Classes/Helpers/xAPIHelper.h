

#import <Foundation/Foundation.h>

#define xapi_not_null(x) (x != nil && ![x isKindOfClass:[NSNull class]])

NS_ASSUME_NONNULL_BEGIN

@interface xAPIHelper : NSObject

+ (NSString*)urlEncode:(NSString*)input;

+ (NSString*)mergeToInput:(NSString*)input queryParams:(NSDictionary*)params;

@end

NS_ASSUME_NONNULL_END
