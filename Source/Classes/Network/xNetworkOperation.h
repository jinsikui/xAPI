

#import "xNetworkAsyncOperation.h"
#import "xNetwork.h"

@interface xNetworkOperation : xNetworkAsyncOperation

- (instancetype)initWithRequestable:(id<xRequestConvertable>)requestable completion:(void(^)(xNetworkResponse *))completion;

- (instancetype)initWithRequestable:(id<xRequestConvertable>)requestable manager:(xNetworkManager *)manager completion:(void(^)(xNetworkResponse *))completion;
@end
