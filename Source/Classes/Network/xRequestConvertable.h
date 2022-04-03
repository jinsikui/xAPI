

#import <Foundation/Foundation.h>
#import "xRequestType.h"
#import "xNetworkSub.h"
#import "xNetworkResponseValider.h"

@class xNetworkResponse;

typedef NS_ENUM(NSInteger,xHTTPMethod){
    HTTP_GET,
    HTTP_POST,
    HTTP_PUT,
    HTTP_DELETE,
    HTTP_OPTIONS,
    HTTP_PATCH,
    HTTP_TRACE,
    HTTP_CONNECT,
    HTTP_HEAD
};

typedef NS_ENUM(NSInteger,xParameterEncoding){
    xParameterEncodingHTTP,
    xParameterEncodingJSON,
    xParameterEncodingPropertyList
};

typedef NS_ENUM(NSInteger,xResponseDecncoding){
    xResponseDecncodingHTTP,
    xResponseDecncodingJSON,
    xResponseDecncodingXML,
};

NS_ASSUME_NONNULL_BEGIN

@protocol xRequestConvertable <NSObject>

/**
 Base URL，例如: http://api.xxx.com
 */
@property (nonatomic, readonly) NSString *  baseURL;

/**
 Path，例如: /u2/user/xxxxxx/login
 */
@property (nonatomic, readonly) NSString *  path;

@optional

/**
 返回给上层的类名称
 
 如果一个网络请求会返回不同的类型给上层，那么请建立网络请求基类，通过继承的方式进行适配
 */
@property (nonatomic, readonly) Class classTypeForResponse;


/**
 默认是Data Request，即拉数据到内存
 */
@property (nonatomic, readonly) xRequestType * requestType;

/**
 请求的参数
 
 GET & DELETE 请求的参数会被编码到Query中，POST & PUT会被添加到Body中
 */
@property (nonatomic, readonly) NSDictionary *  parameters;

/**
 请求的HTPT方法
 */
@property (nonatomic, readonly) xHTTPMethod httpMethod; //默认GET

/**
 HTTP的header
 */
@property (nonatomic, readonly) NSDictionary<NSString *,NSString *> * httpHeaders;

/**
 参数的编码方式，默认会按照HTTP的方式进行编码
 */
@property (nonatomic, readonly) xParameterEncoding encodingType;

/**
 返回NSData的解码方式，默认按照JSON来解析
 */
@property (nonatomic, readonly) xResponseDecncoding decodingType;//默认JSON

/**
 如果提供这个方法，那么不会实际进行网络请求，而是以stubData中的数据和模式进行返回
 */
@property (nonatomic, readonly) xNetworkSub * stubData;

/**
 在多少秒内如果相同的请求发出，当缓存有数据的时候，返回缓存数据
 */
@property (nonatomic, readonly) NSTimeInterval durationForReturnCache;

/**
 支持的Response Content-Type的额外类型
 */
@property (nonatomic, strong) NSSet * acceptableContentTypes;

/**
 对返回的response进行适配，这个方法在后台线程执行
 @param networkResponse 返回的response
 @return 适配后的结果，不可为空
 */
- (xNetworkResponse *)adaptResponse:(xNetworkResponse *)networkResponse;

/**
 对请求进行有效性验证
 */
@property (nonatomic, readonly) id<xNetworkResponseValider> responseValider;

/**
 如果失败的重试次数，默认不会重试
 */
@property (nonatomic, assign) NSUInteger retryTimes;

/**
 是否要把NSNull的从JSON中删除
 */
@property (nonatomic, assign) BOOL removesKeysWithNullValues;

@end

NS_ASSUME_NONNULL_END
