

#import <Foundation/Foundation.h>
#import "xRequestConvertable.h"

@protocol xRequestConvertable;

extern NSString * const xNetworkErrorDomain;

typedef NS_ENUM(NSInteger, xNetworkErrorCode){
    xNetworkErrorCanceled = -400001, //请求被取消
    xNetworkErrorFailToAdaptsNetworkRequest = -400002, //从Requstable -> xNeworkRequest转换失败
    xNetworkErrorFailToAdaptURLRequest = -400003, //从sNeworkRequest -> URLRequst转换失败
    xNetworkErrorFailToAdaptedResponse = -400005,//请求的-[xRequestConvertable adaptResponse:]适配失败
};


/**
 响应对象的来源

 - xNetworkResponseSourceStub: 由假数据返回，假数据由Requestable提供
 - xNetworkResponseSourceLocalCache: 由本地缓存提供
 - xNetworkResponseSourceURLLoadingSystem: 由URL Loading System提供
 */
typedef NS_ENUM(NSInteger, xNetworkResponseSource){
    xNetworkResponseSourceStub,
    xNetworkResponseSourceLocalCache,
    xNetworkResponseSourceURLLoadingSystem
};

/**
   网络请求返回给上层的对象
 */
@interface xNetworkResponse<T> : NSObject

/**
 网络请求返回的对象，默认当作JSON解析的，这个对象是经过Requestable适配后的对象
 */
@property (strong, nonatomic, readonly) T responseObject;

/**
 网络请求的HTTP Response
 */
@property (strong, nonatomic, readonly) NSURLResponse * urlResponse;

/**
 网络请求的错误，没有Error说明请求成功
 */
@property (strong, nonatomic, readonly) NSError * error;

/**
 状态码
 */
@property (assign, nonatomic,readonly) NSInteger statusCode;

/**
 原始的请求
 */
@property (strong, nonatomic,readonly) id <xRequestConvertable> requestConvertable;

/**
 下载文件的路径（只有download任务有效）
 */
@property (strong, nonatomic, readonly) NSURL * filePath;

/**
 数据的来源
 */
@property (assign, nonatomic, readonly) xNetworkResponseSource source;

- (instancetype)initWithRequest:(id<xRequestConvertable>)request
                    urlResponse:(NSURLResponse *)urlResponse
                   responseData:(NSData *)data
                          error:(NSError *)error;


- (instancetype)initWithRequest:(id<xRequestConvertable>)request
                    urlResponse:(NSURLResponse *)urlResponse
                       filePath:(NSURL *)filePath
                          error:(NSError *)error;


- (instancetype)initWithRequest:(id<xRequestConvertable>)request
                    urlResponse:(NSURLResponse *)urlResponse
                   responseData:(NSData *)data
                          error:(NSError *)error
                         source:(xNetworkResponseSource)source;

- (instancetype)initWithRequest:(id<xRequestConvertable>)request
                    urlResponse:(NSURLResponse *)urlResponse
                       filePath:(NSURL *)filePath
                          error:(NSError *)error
                         source:(xNetworkResponseSource)source;


- (instancetype)initStubResponseWithRequest:(id<xRequestConvertable>)request data:(xNetworkSub *)data;

- (instancetype)initWithResponse:(xNetworkResponse *)response adpatedObject:(id)object;
- (instancetype)initWithResponse:(xNetworkResponse *)response udpatedError:(NSError *)error;
@end
