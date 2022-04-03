

#import <Foundation/Foundation.h>
#import "xAPIDepends.h"

#define xAPIErrorDomain @"xAPIErrorDomain"
#define xAPIErrorMessageKey @"xAPIErrorMessageKey"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, xAPICommonParamsUsage) {
    xAPICommonParamsUsageNone = 0,
    xAPICommonParamsUsagePath = 1 << 1,
    xAPICommonParamsUsageParams = 1 << 2,
};

typedef NS_ENUM(NSUInteger, xAPICommonHeadersUsage) {
    xAPICommonHeadersUsageNone = 0,
    xAPICommonHeadersUsageHeaders = 1 << 1,
};

typedef FBLPromise * _Nullable (^SAPIBeforeNetworkCallbackBlock)(void);
typedef NSDictionary * _Nonnull (^SAPISetParamsBlock)(NSString *_Nullable);
typedef NSDictionary * _Nonnull (^SAPISetHeadersBlock)(NSString *_Nullable);

@interface xAPIBaseBuilder : NSObject

@property (nonatomic, copy, nullable, readonly) SAPISetParamsBlock paramsBlock;
@property (nonatomic, copy, nullable, readonly) SAPISetHeadersBlock headersBlock;
@property(nonatomic, strong, readonly) void (^commonParams)(SAPISetParamsBlock commonParamsBlock);
@property(nonatomic, strong, readonly) void (^commonHeaders)(SAPISetHeadersBlock commonHeadersBlock);
@property (nonatomic, copy, readonly) void (^defaultHost)(NSString *defaultHost);
@property (nonatomic, assign, readonly) void (^defaultMethod)(xHTTPMethod defaultMethod);

+ (instancetype)shared;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface xAPIConvertable : NSObject <xRequestConvertable>

- (instancetype)initWithParams:(NSDictionary * _Nullable)params
                       headers:(NSDictionary * _Nullable)headers
                          host:(NSString * _Nullable)host
                          path:(NSString * _Nullable)path
                        method:(xHTTPMethod)method
                  encodingType:(xParameterEncoding)encodingType
                  decodingType:(xResponseDecncoding)decodingType
                      stubData:(xNetworkSub* _Nullable)stubData;
@end

@interface xAPIBuilder : NSObject
/// 设置一个标志，传给构造commonParams和commonHeaders的block
@property (nonatomic, copy, readonly) xAPIBuilder * (^tag)(NSString *tag);
@property (nonatomic, copy, readonly) xAPIBuilder * (^stubData)(xNetworkSub *stubData);
@property (nonatomic, copy, readonly) xAPIBuilder * (^params)(NSDictionary *params);
@property (nonatomic, copy, readonly) xAPIBuilder * (^headers)(NSDictionary *headers);
@property(nonatomic, assign, readonly) xAPIBuilder * (^commonParamsUsage)(xAPICommonParamsUsage commonParamsUsage);
@property(nonatomic, assign, readonly) xAPIBuilder * (^commonHeadersUsage)(xAPICommonHeadersUsage commonHeadersUsage);
@property(nonatomic, copy, readonly) xAPIBuilder * (^host)(NSString *host);
@property(nonatomic, copy, readonly) xAPIBuilder * (^path)(NSString *path);
@property(nonatomic, assign, readonly) xAPIBuilder * (^method)(xHTTPMethod method);
@property(nonatomic, assign, readonly) xAPIBuilder * (^encodingType)(xParameterEncoding encodingType);
@property(nonatomic, assign, readonly) xAPIBuilder * (^decodingType)(xResponseDecncoding decodingType);
@property(nonatomic, copy, readonly) xAPIBuilder * (^beforeNetworkCallback)(SAPIBeforeNetworkCallbackBlock beforeCallback);
@property(nonatomic, copy, readonly) FBLPromise * (^execute)(void);

@end

@interface xAPI : NSObject

#pragma mark - Common API Properties

+ (void)buildCommon:(void(^)(xAPIBaseBuilder *baseBuilder))block;
@property(nonatomic, strong, class, readonly) void (^commonParams)(SAPISetParamsBlock commonParamsBlock);
@property(nonatomic, strong, class, readonly) void (^commonHeaders)(SAPISetHeadersBlock commonHeadersBlock);
@property (nonatomic, copy, class, readonly) void (^defaultHost)(NSString *defaultHost);
@property (nonatomic, assign, class, readonly) void (^defaultMethod)(xHTTPMethod defaultMethod);

#pragma mark - Instance API Properties

+ (xAPIBuilder *)build:(void(^_Nullable)(xAPIBuilder *builder))block;
@property(nonatomic, strong, class, readonly) xAPIBuilder * (^tag)(NSString *tag);
@property(nonatomic, strong, class, readonly) xAPIBuilder * (^stubData)(xNetworkSub *stubData);
@property(nonatomic, strong, class, readonly) xAPIBuilder * (^params)(NSDictionary *params);
@property(nonatomic, strong, class, readonly) xAPIBuilder * (^headers)(NSDictionary *headers);
@property(nonatomic, assign, class, readonly) xAPIBuilder * (^commonParamsUsage)(xAPICommonParamsUsage commonParamsUsage);
@property(nonatomic, assign, class, readonly) xAPIBuilder * (^commonHeadersUsage)(xAPICommonHeadersUsage commonHeadersUsage);
@property(nonatomic, copy, class, readonly) xAPIBuilder * (^host)(NSString *host);
@property(nonatomic, copy, class, readonly) xAPIBuilder * (^path)(NSString *path);
@property(nonatomic, assign, class, readonly) xAPIBuilder * (^method)(xHTTPMethod method);
@property(nonatomic, assign, class, readonly) xAPIBuilder * (^encodingType)(xParameterEncoding encodingType);
@property(nonatomic, copy, class, readonly) xAPIBuilder * (^beforeNetworkCallback)(SAPIBeforeNetworkCallbackBlock beforeCallback);

@end

NS_ASSUME_NONNULL_END
