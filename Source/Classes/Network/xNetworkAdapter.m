

#import "xNetworkAdapter.h"
#import "xNetworkRequest.h"

@implementation xNetworkRequestDefaultAdapter

- (void)adaptRequestConvertable:(id<xRequestConvertable>)requestConvertable
                       complete:(void (^)(xNetworkRequest * ,NSError *  error))complete{
    NSError * error;
    xNetworkRequest * request = [[xNetworkRequest alloc]
                                  initWithRequestConvertable:requestConvertable
                                  error:&error];
    complete(request,error);
}

+ (instancetype)adapter{
    return [[xNetworkRequestDefaultAdapter alloc] init];
}

@end


@implementation xNetworkURLDefaultAdapter

+ (instancetype)adapter{
    return [[xNetworkURLDefaultAdapter alloc] init];
}
- (void)adaptRequest:(xNetworkRequest * )requset
            complete:(void(^)(NSURLRequest *  request,NSError * error))complete{
    NSURLRequest * urlRequest = requset.urlRequest;
    complete(urlRequest,nil);
}

@end
