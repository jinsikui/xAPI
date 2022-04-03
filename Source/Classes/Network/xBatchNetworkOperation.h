

#import "xNetworkAsyncOperation.h"
#import "xNetwork.h"
/**
 一组网络请求，只有请求都完成才会回调completion
 */
@interface xBatchNetworkOperation : xNetworkAsyncOperation

/**
 同一个对象不能被添加到Array里两次，否则会引起混乱
 */
- (instancetype)initWithRequestables:(NSArray *)requestables
                          completion:(void(^)(NSArray<xNetworkResponse *> *))completion;

- (instancetype)initWithRequestables:(NSArray *)requestables
                             manager:(xNetworkManager *)manager
                          completion:(void(^)(NSArray<xNetworkResponse *> *))completion;
@end
