

#import <Foundation/Foundation.h>
#import "xNetworkRequest.h"
#import "xNetworkResponse.h"

NS_ASSUME_NONNULL_BEGIN
/**
 网络框架插件，注意插件的代理方法往往不在主线程执行
 */
@protocol xNetworkPlugin<NSObject>

@optional

/**
 将要开始适配convertable，即convertable->xNetworkRequest的转化
 */
- (void)willAdaptRequestConvertable:(id<xRequestConvertable>)convertable;

/**
 完成适配convertable，即convertable->xNetworkRequest的转化
 */
- (void)didAdaptedRequestConvertable:(id<xRequestConvertable>)convertable
                          withResult:(xNetworkRequest *)request
                               error:(NSError *)error;
/**
 将要开始适配request，即request->URLRequest的转化
 */
- (void)willAdaptRequest:(xNetworkRequest *)request;

/**
 完成开始适配request，即request->URLRequest的转化
 */
- (void)didAdaptedRequest:(xNetworkRequest *)request 
               withResult:(NSURLRequest *)urlRequest
                    error:(NSError *)error;
/**
 收到AFN的原始数据
 */
- (void)didReceiveResponse:(NSURLResponse *)response
            responseObject:(id _Nullable)responseObject
                  filePath:(NSURL * _Nullable)filePath
                     error:(NSError *)error;
/**
 将要进行返回对象的适配
 */
- (void)willAdaptResponse:(xNetworkResponse *)response;

/**
 完成返回对象的适配
 */
- (void)didAdaptedResponse:(xNetworkResponse *)responser;

@end

NS_ASSUME_NONNULL_END
