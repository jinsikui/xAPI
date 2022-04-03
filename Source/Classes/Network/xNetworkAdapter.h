

#import <Foundation/Foundation.h>
#import "xRequestConvertable.h"

@class xNetworkRequest;
NS_ASSUME_NONNULL_BEGIN

@protocol xNetworkRequestAdapter <NSObject>

/**
 适配方法，在这个方法里，把sRequestConvertable转换成sNetworkRequst

 @param requestConvertable 请求
 @param complete 当你完成了sRequestConvertable->xNetworkRequst转换后，执行complete闭包，如果出错传入Error对象，传入error对象后，网络请求不会继续进行
 */
- (void)adaptRequestConvertable:(id<xRequestConvertable>)requestConvertable
                       complete:(void(^)(xNetworkRequest *  request, NSError *  error))complete;

@end

@protocol xNetworkURLAdapter <NSObject>

/**
 适配方法，在这个方法里，把sNetworkRequest转换成NSURLRequest
 
 @param requset xNetworkRequest请求
 @param complete 当你完成了sNetworkRequest->NSURLRequest转换后，执行complete闭包，如果出错传入Error对象，传入error对象后，网络请求不会继续进行
 */
- (void)adaptRequest:(xNetworkRequest * )requset
            complete:(void(^)(NSURLRequest *  request,NSError * error))complete;

@end

/**
 默认的sNetworkRequst适配
 */
@interface xNetworkRequestDefaultAdapter : NSObject<xNetworkRequestAdapter>

- (void)adaptRequestConvertable:(id<xRequestConvertable> )requestConvertable
                       complete:(void(^)(xNetworkRequest *  request, NSError *  error))complete;

+ (instancetype)adapter;
@end

/**
 默认的URLRequest适配
 */
@interface xNetworkURLDefaultAdapter : NSObject <xNetworkURLAdapter>

- (void)adaptRequest:(xNetworkRequest * )requset
            complete:(void(^)(NSURLRequest *  request,NSError * error))complete;

+ (instancetype)adapter;

@end

NS_ASSUME_NONNULL_END
