

#import "xNetworkAsyncOperation.h"
#import "xNetwork.h"

@protocol  xChainRequestable <xRequestConvertable>

/**
 收到了上一个网络请求的完成回调，在这里决定是否要继续进行下一个网络请求

 */
- (BOOL)shouldStartNextWithResponse:(xNetworkResponse *)response error:(NSError **)error;

@end

@interface xChainNetworkOperation : xNetworkAsyncOperation

/**
 同一个对象不能被添加到Array里两次，否则会引起混乱
 */
- (instancetype)initWithRequestables:(NSArray *)requestables
                          completion:(void(^)(xNetworkResponse * lastActiveResponse))completion;

- (instancetype)initWithRequestables:(NSArray *)requestables
                             manager:(xNetworkManager *)manager
                          completion:(void(^)(xNetworkResponse * lastActiveResponse))completion;

@end
