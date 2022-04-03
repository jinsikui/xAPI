
#import <Foundation/Foundation.h>

extern NSString * const xNetworkResponseValiderErrorDomain;

@protocol xNetworkResponseValider<NSObject>

- (BOOL)validResponse:(id)json error:(NSError **)error;


@end

/**
 对JSON的Schema进行验证
 */
@interface xJSONSchemaValider : NSObject <xNetworkResponseValider>

/**
 对JSON Array进行验证，

 @param scheme JSON的Scheme
 */
+ (instancetype)arrayValiderWithScheme:(NSArray *)scheme;

/**
 对JSON Object进行验证，
 
 @param scheme JSON的Scheme
 */
+ (instancetype)objectValiderWithScheme:(NSDictionary *)scheme;

@end
