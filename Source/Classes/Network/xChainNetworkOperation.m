

#import "xChainNetworkOperation.h"
#import "xNetworkOperation.h"
#import <objc/runtime.h>

@interface xChainNetworkOperation()

@property (strong, nonatomic) NSArray * requestables;
@property (strong, nonatomic) xNetworkManager * manager;
@property (strong, nonatomic) void(^completion)(xNetworkResponse * lastActiveResponse);
@property (strong, nonatomic) NSString * udidKey;
@property (strong, nonatomic) xNetworkResponse * lastResponse;
@property (strong, nonatomic) NSOperationQueue * queue;
@end



@implementation xChainNetworkOperation

- (instancetype)initWithRequestables:(NSArray *)requestables completion:(void(^)(xNetworkResponse * lastActiveResponse))completion{
    return [self initWithRequestables:requestables
                              manager:[xNetworkManager manager]
                           completion:completion];
}
- (instancetype)initWithRequestables:(NSArray *)requestables
                             manager:(xNetworkManager *)manager
                          completion:(void(^)(xNetworkResponse * lastActiveResponse))completion{
    if (self = [super init]) {
        self.requestables = requestables;
        self.manager = manager;
        self.completion = completion;
        self.udidKey = [[NSUUID UUID] UUIDString];
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)execute{
    NSBlockOperation * finishOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completion) {
                self.completion(self.lastResponse);
            }
        });
        [self finishOperation];
    }];
    [self.requestables enumerateObjectsUsingBlock:^(id<xRequestConvertable> requestable, NSUInteger idx, BOOL * _Nonnull stop) {
        objc_setAssociatedObject(requestable, [self.udidKey UTF8String], @(idx), OBJC_ASSOCIATION_RETAIN);
        xNetworkOperation * operation = [[xNetworkOperation alloc] initWithRequestable:requestable
                                                                                 manager:self.manager
                                                                              completion:^(xNetworkResponse * response) {
                                                                                  if (response.error) {//请求失败，取消全部任务
                                                                                      if(self.completion){
                                                                                          self.completion(response);
                                                                                      }
                                                                                      [self.queue cancelAllOperations];
                                                                                  }else{
                                                                                      if ([requestable conformsToProtocol:@protocol(xChainRequestable)]) {
                                                                                          id<xChainRequestable> chainRequest = (id)requestable;
                                                                                          NSError * error;
                                                                                          BOOL shouldStartNext = [chainRequest shouldStartNextWithResponse:response error:&error];
                                                                                          if (!shouldStartNext) {
                                                                                              if (!error) {
                                                                                                  error = [NSError errorWithDomain:xNetworkErrorDomain
                                                                                                                              code:-1000010
                                                                                                                          userInfo:@{@"Reason":@"Chain request decide not to contine"}];
                                                                                              }
                                                                                              xNetworkResponse * adaptedResponse = [[xNetworkResponse alloc] initWithResponse:response udpatedError:error];
                                                                                              if(self.completion){
                                                                                                  self.completion(adaptedResponse);
                                                                                              }
                                                                                              [self.queue cancelAllOperations];
                                                                                          }else{
                                                                                              self.lastResponse = response;
                                                                                          }
                                                                                      }else{
                                                                                          self.lastResponse = response;
                                                                                      }
                                                                                  }
                                                                              }];
        [self.queue addOperation:operation];
    }];
    [self.queue addOperation:finishOperation];
}

- (void)cancel{
    [self.queue cancelAllOperations];
    [super cancel];
}

@end
