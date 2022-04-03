

#import "xNetworkOperation.h"

@interface xNetworkOperation()

@property (strong, nonatomic) id<xRequestConvertable> requestable;

@property (copy, nonatomic) void (^completion)(xNetworkResponse *);

@property (strong, nonatomic) xNetworkManager * manager;

@property (strong, nonatomic) id<xRequstToken> token;
@end

@implementation xNetworkOperation

- (instancetype)initWithRequestable:(id<xRequestConvertable>)requestable completion:(void (^)(xNetworkResponse *))completion{
    return [self initWithRequestable:requestable
                             manager:[xNetworkManager manager]
                          completion:completion];
}

- (instancetype)initWithRequestable:(id<xRequestConvertable>)requestable
                            manager:(xNetworkManager *)manager
                         completion:(void (^)(xNetworkResponse *))completion{
    if (self = [super init]) {
        self.requestable = requestable;
        self.completion = completion;
        self.manager = manager;
    }
    return self;
}

- (void)pause{
    [self.token suspend];
    [super pause];
}

- (void)resume{
    [self.token resume];
    [super resume];
}

- (void)execute{
    self.token = [self.manager request:self.requestable
                            completion:^(xNetworkResponse * _Nonnull response) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self.completion(response);
                                });
                                [self finishOperation];
                            }];
}

- (void)cancel{
    if (self.token) {
        [self.token cancel];
    }
    [super cancel];
}

@end
