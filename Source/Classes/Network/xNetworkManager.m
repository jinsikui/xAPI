

#import "xNetworkManager.h"
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif
#import "xNetworkAdapter.h"
#import "NSURLRequest+xNetwork.h"
#import "xNetworkCache.h"

typedef void(^xAFDataTaskCompletionBlock)(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error);
typedef void(^xAFDownloadTaskCompletionBlock)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error);;

#define BEGIN_ASYNC_MANAGER_QUEUE dispatch_async(self.queue, ^{
#define END_ASYNC_MANAGER_QUEU });

#define BEGIN_ASYNC_MAIN_QUEUE dispatch_async(dispatch_get_main_queue(), ^{
#define END_ASYNC_MAIN_QUEU });

@interface xRequstToken : NSObject <xRequstToken>

+ (instancetype)token;

@property (strong, nonatomic) NSURLSessionTask * task;
@property (assign, nonatomic) BOOL isCanceled;

@end

@interface xRequstToken()

@end

@implementation xRequstToken

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isCanceled = NO;
    }
    return self;
}
- (xRequstTokenState)state{
    switch (self.task.state) {
        case NSURLSessionTaskStateRunning:
            return xRequstTokenStateRunning;
        case NSURLSessionTaskStateCanceling:
            return xRequstTokenStateCanceling;
        case NSURLSessionTaskStateCompleted:
            return xRequstTokenStateCompleted;
        case NSURLSessionTaskStateSuspended:
            return xRequstTokenStateSuspended;
    }
}

- (void)suspend{
    [self.task suspend];
}

- (void)resume{
    [self.task resume];
}

- (void)cancel{
    [self.task cancel];
    _isCanceled = YES;
}

+ (instancetype)token{
    return [[xRequstToken alloc] init];
}

@end



@interface xNetworkManager()

@property (strong, nonatomic) NSRecursiveLock * lock;

@property (strong, nonatomic) id<xNetworkRequestAdapter> requestAdapter;

@property (strong, nonatomic) id<xNetworkURLAdapter> urlAdapter;

@property (strong, nonatomic) AFURLSessionManager * afSessionManager;

@property (strong, nonatomic) dispatch_queue_t queue;

@property (assign, nonatomic, readonly) BOOL trackRepeatRequest;

@property (strong, nonatomic) NSMutableDictionary * callbackMap;//URLRequst -> CallBcaks

@property (strong, nonatomic) NSArray * plugins;

@end

@implementation xNetworkManager

- (void)setSecurityPolicy:(AFSecurityPolicy *)securityPolicy{
    self.afSessionManager.securityPolicy = securityPolicy;
}

- (void)cancelAllOperations{
    [self.lock lock];
    [self.afSessionManager.operationQueue cancelAllOperations];
    self.callbackMap = [NSMutableDictionary new];
    [self.lock unlock];
}
- (void)pauseAllOpertaions{
    [self.lock lock];
    
}
+ (instancetype)shared{
    static xNetworkManager * _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [xNetworkManager manager];
    });
    return _instance;
}
+ (instancetype)manager{
    return [[xNetworkManager alloc] initWithConfiguraiton:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (instancetype)initWithConfiguraiton:(NSURLSessionConfiguration *)sessionConfiguration
                       requestAdapter:(id<xNetworkRequestAdapter> )requestAdapter
                           urlAdapter:(id<xNetworkURLAdapter> )urlAdapter
                              plugins:(NSArray<id<xNetworkPlugin>> *)plugins
                   trackRepeatRequest:(BOOL)trackRepeactRequest{
    NSParameterAssert(sessionConfiguration != nil);
    NSParameterAssert(requestAdapter != nil && [requestAdapter conformsToProtocol:@protocol(xNetworkRequestAdapter)]);
    NSParameterAssert(urlAdapter != nil && [urlAdapter conformsToProtocol:@protocol(xNetworkURLAdapter)]);
    if (self = [super init]) {
        self.requestAdapter = requestAdapter;
        self.urlAdapter = urlAdapter;
        //iOS 11.3的某些机型上，设置cache会造成无限crash
        sessionConfiguration.URLCache = nil;
        self.afSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
        self.afSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        self.queue = dispatch_queue_create("com.snetwork.sessionManager.queue", DISPATCH_QUEUE_SERIAL);
        _trackRepeatRequest = trackRepeactRequest;
        if (self.trackRepeatRequest) {
            self.callbackMap = [NSMutableDictionary new];
        }
        self.plugins = plugins;
        self.lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}
- (instancetype)initWithConfiguraiton:(NSURLSessionConfiguration *)sessionConfiguration
                   trackRepeatRequest:(BOOL)trackRepeactRequest{
    xNetworkRequestDefaultAdapter * requestAdapter = [[xNetworkRequestDefaultAdapter alloc] init];
    xNetworkURLDefaultAdapter * urlAdapter = [[xNetworkURLDefaultAdapter alloc] init];
    return [self initWithConfiguraiton:sessionConfiguration
                        requestAdapter:requestAdapter
                            urlAdapter:urlAdapter
                               plugins:nil
                    trackRepeatRequest:trackRepeactRequest];
}
- (instancetype)initWithConfiguraiton:(NSURLSessionConfiguration *)sessionConfiguration{
    xNetworkRequestDefaultAdapter * requestAdapter = [[xNetworkRequestDefaultAdapter alloc] init];
    xNetworkURLDefaultAdapter * urlAdapter = [[xNetworkURLDefaultAdapter alloc] init];
    return [self initWithConfiguraiton:sessionConfiguration
                        requestAdapter:requestAdapter
                            urlAdapter:urlAdapter
                               plugins:nil
                    trackRepeatRequest:NO];
}

- (id<xRequstToken>)request:(id<xRequestConvertable>)requestConvertable
     completion:(void (^)(xNetworkResponse * _Nonnull))completion{
    return [self request:requestConvertable
                progress:nil
              completion:completion];
}

- (id<xRequstToken>)request:(id<xRequestConvertable>)requestConvertable
                   progress:(xNetworkResposeProgress )progress
                 completion:(xNetworkResposeComplete)completion{
    NSParameterAssert(requestConvertable != nil);
    xRequstToken * token = [xRequstToken token];
    //Plugins
    for (id<xNetworkPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(willAdaptRequestConvertable:)]) {
            [plugin willAdaptRequestConvertable:requestConvertable];
        }
    }
    [self.requestAdapter adaptRequestConvertable:requestConvertable
                                        complete:^(xNetworkRequest * _Nonnull request, NSError * _Nonnull error) {
                                            //Plugins
                                            for (id<xNetworkPlugin> plugin in self.plugins) {
                                                if ([plugin respondsToSelector:@selector(didAdaptedRequestConvertable:withResult:error:)]) {
                                                    [plugin didAdaptedRequestConvertable:requestConvertable withResult:request error:error];
                                                }
                                            }
                                            if (error) {
                                                [self envokeCompletion:completion withError:error request:requestConvertable];
                                                return;
                                            }
                                            if (token.isCanceled) {
                                                NSError * error = [NSError errorWithDomain:xNetworkErrorDomain
                                                                                      code:xNetworkErrorCanceled
                                                                                  userInfo:nil];
                                                [self envokeCompletion:completion withError:error request:requestConvertable];
                                                return;
                                            }
                                            if (request == nil) {
                                                NSError * error = [NSError errorWithDomain:xNetworkErrorDomain
                                                                                      code:xNetworkErrorFailToAdaptsNetworkRequest
                                                                                  userInfo:nil];
                                                [self envokeCompletion:completion withError:error request:requestConvertable];
                                                return;
                                            }
                                            //Plugins
                                            for (id<xNetworkPlugin> plugin in self.plugins) {
                                                if ([plugin respondsToSelector:@selector(willAdaptRequest:)]) {
                                                    [plugin willAdaptRequest:request];
                                                }
                                            }
                                            [self.urlAdapter adaptRequest:request
                                                                 complete:^(NSURLRequest * _Nonnull urlRequest, NSError * _Nonnull error) {
                                                                     //Plugins
                                                                     for (id<xNetworkPlugin> plugin in self.plugins) {
                                                                         if ([plugin respondsToSelector:@selector(didAdaptedRequest:withResult:error:)]) {
                                                                             [plugin didAdaptedRequest:request withResult:urlRequest error:error];
                                                                         }
                                                                     }
                                                                     if (error) {
                                                                         [self envokeCompletion:completion withError:error request:requestConvertable];
                                                                         return;
                                                                     }
                                                                     if (token.isCanceled) {
                                                                         NSError * error = [NSError errorWithDomain:xNetworkErrorDomain
                                                                                                               code:xNetworkErrorCanceled
                                                                                                           userInfo:nil];
                                                                         [self envokeCompletion:completion withError:error request:requestConvertable];
                                                                         return;
                                                                     }
                                                                     if (urlRequest == nil) {
                                                                         NSError * error = [NSError errorWithDomain:xNetworkErrorDomain
                                                                                                               code:xNetworkErrorFailToAdaptURLRequest
                                                                                                           userInfo:nil];
                                                                         [self envokeCompletion:completion withError:error request:requestConvertable];
                                                                         return;
                                                                     }
                                                                     if ([requestConvertable respondsToSelector:@selector(stubData)]) {//走假数据模式
                                                                         if ([requestConvertable stubData] != nil) {
                                                                             [self envokeSubWithrequestConvertable:requestConvertable
                                                                                                        urlRequest:urlRequest
                                                                                                        completion:completion];
                                                                             return;
                                                                         }
                                                                     }
                                                                     //重复网络请求检查
                                                                     if(self.trackRepeatRequest){
                                                                         [self.lock lock];
                                                                         NSString * requestID = urlRequest.x_unqiueIdentifier;
                                                                         NSArray * callBacks = [self.callbackMap objectForKey:requestID];
                                                                         NSMutableArray * updatedCallbacks;
                                                                         if (callBacks == nil) {
                                                                             updatedCallbacks = [NSMutableArray new];
                                                                         }else{
                                                                             updatedCallbacks = [[NSMutableArray alloc] initWithArray:callBacks];
                                                                         }
                                                                         if (completion) {
                                                                             [updatedCallbacks addObject:completion];
                                                                         }
                                                                         NSArray * array = [[NSArray alloc] initWithArray:updatedCallbacks];
                                                                         [self.callbackMap setObject:array forKey:requestID];
                                                                         [self.lock unlock];
                                                                         if (array.count > 1) {//同时存在几个一样的请求
                                                                             return;
                                                                         }
                                                                     }
                                                                     if ([requestConvertable respondsToSelector:@selector(durationForReturnCache)]) {
                                                                         NSTimeInterval duration = [requestConvertable durationForReturnCache];
                                                                         xNetworkCacheItem * item = [xNetworkCache cachedDataForRequest:urlRequest expire:duration];
                                                                         if (item) {//有缓存数据
                                                                             [self envokeCacheCallBackWithrequestConvertable:requestConvertable
                                                                                                           urlRequest:urlRequest
                                                                                                           cachedItem:item
                                                                                                           completion:completion];
                                                                             return;
                                                                         }
                                                                     }
                                                                     NSInteger retryTimes = [requestConvertable respondsToSelector:@selector(retryTimes)] ? [requestConvertable retryTimes] - 1: 0;
                                                                     [self startTaskWithRequestConvertable:requestConvertable
                                                                                                urlRequest:urlRequest
                                                                                                     token:token
                                                                                              toRetryTimes:retryTimes
                                                                                                  progress:progress
                                                                                                completion:completion];
                                                                 }];
                                        }];
    return token;
    
}

- (void)envokeCompletion:(void(^)(xNetworkResponse * response))completion withError:(NSError *)error request:(id<xRequestConvertable>) requestConvertable{
    xNetworkResponse * response = [[xNetworkResponse alloc] initWithRequest:requestConvertable urlResponse:nil responseData:nil error:error];
    xNetworkResponse * adaptedResponse = [self adaptedResponseWithOriginal:response requestConvertable:requestConvertable];
    BEGIN_ASYNC_MAIN_QUEUE
    if (completion) {
        completion(adaptedResponse);
    }
    END_ASYNC_MAIN_QUEU
}

- (void)envokeCacheCallBackWithrequestConvertable:(id<xRequestConvertable>)requestConvertable
                                       urlRequest:(NSURLRequest *)urlRequest
                                       cachedItem:(xNetworkCacheItem *)item
                                       completion:(void(^)(xNetworkResponse *  response))completion{
    BEGIN_ASYNC_MANAGER_QUEUE
    xNetworkResponse * response = [[xNetworkResponse alloc] initWithRequest:requestConvertable
                                                                  urlResponse:item.httpResponse
                                                                 responseData:item.data
                                                                        error:nil
                                                                       source:xNetworkResponseSourceLocalCache];
    if(self.trackRepeatRequest){
        [self.lock lock];
        NSString * requestID = urlRequest.x_unqiueIdentifier;
        NSArray * callBacks = [self.callbackMap objectForKey:requestID];
        for (xNetworkResposeComplete callback in callBacks) {
            [self envokeCallBack:callback withResponse:response requestConvertable:requestConvertable];
        }
        [self.callbackMap removeObjectForKey:requestID];
        [self.lock unlock];
    }else{
        [self envokeCallBack:completion withResponse:response requestConvertable:requestConvertable];
    }
    END_ASYNC_MANAGER_QUEU
}
- (void)envokeSubWithrequestConvertable:(id<xRequestConvertable>)requestConvertable
                      urlRequest:(NSURLRequest *)urlRequest
                      completion:(void(^)(xNetworkResponse *  response))completion{
    BEGIN_ASYNC_MANAGER_QUEUE
    xNetworkSub * stub = [requestConvertable stubData];
    xNetworkResponse * response;
    if (stub.sampleData) {
        response = [[xNetworkResponse alloc] initStubResponseWithRequest:requestConvertable
                                                                     data:stub];
        dispatch_after(DISPATCH_TIME_NOW + stub.delay, self.queue, ^{
            if(self.trackRepeatRequest){
                [self.lock lock];
                NSString * requestID = urlRequest.x_unqiueIdentifier;
                NSArray * callBacks = [self.callbackMap objectForKey:requestID];
                for (xNetworkResposeComplete  callback in callBacks) {
                    [self envokeCallBack:callback withResponse:response requestConvertable:requestConvertable];
                }
                [self.callbackMap removeObjectForKey:requestID];
                [self.lock unlock];
            }else{
                [self envokeCallBack:completion withResponse:response requestConvertable:requestConvertable];
            }
        });
    }
    END_ASYNC_MANAGER_QUEU
}

//适配Resoonse
- (xNetworkResponse *)adaptedResponseWithOriginal:(xNetworkResponse *)response requestConvertable:(id<xRequestConvertable>)requestConvertable{
    for (id<xNetworkPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(willAdaptResponse:)]) {
            [plugin willAdaptResponse:response];
        }
    }
    xNetworkResponse * adaptedResponse;
    if ([requestConvertable respondsToSelector:@selector(adaptResponse:)]) {
        adaptedResponse = [requestConvertable adaptResponse:response];
        NSAssert(adaptedResponse != nil, @"You can not return a empty response here");
        NSString * reason = nil;
        NSError * error;
        if (adaptedResponse.responseObject == nil && !response.error) {
            reason =  @"We got empty responseObject";
        }
        if ([requestConvertable respondsToSelector:@selector(classTypeForResponse)]) {
            Class rightClass = [requestConvertable classTypeForResponse];
            if (![[adaptedResponse responseObject] isKindOfClass:rightClass]) {//类型不对
                reason = [NSString stringWithFormat: @"The reqeust claims that responseObject class is %@, but we got %@",rightClass,[adaptedResponse.responseObject class]];
            }
        }
        if (reason != nil) {
            error = [NSError errorWithDomain:xNetworkErrorDomain
                                        code:xNetworkErrorFailToAdaptedResponse
                                    userInfo:@{@"reason":reason}];
        }
        if (error) {
            adaptedResponse = [[xNetworkResponse alloc] initWithResponse:response udpatedError:error];
            adaptedResponse = [[xNetworkResponse alloc] initWithResponse:adaptedResponse adpatedObject:nil];
        }
    }else{
        adaptedResponse = response;
    }
    for (id<xNetworkPlugin> plugin in self.plugins) {
        if ([plugin respondsToSelector:@selector(didAdaptedResponse:)]) {
            [plugin didAdaptedResponse:response];
        }
    }
    return adaptedResponse;
}

- (void)envokeCallBack:(xNetworkResposeComplete)callback
          withResponse:(xNetworkResponse *)response
           requestConvertable:(id<xRequestConvertable>)requestConvertable{
    xNetworkResponse * adaptedResponse = [self adaptedResponseWithOriginal:response requestConvertable:requestConvertable];
    BEGIN_ASYNC_MAIN_QUEUE
    callback(adaptedResponse);
    END_ASYNC_MAIN_QUEU
}

- (void)startTaskWithRequestConvertable:(id<xRequestConvertable>)requestConvertable
                             urlRequest:(NSURLRequest *)urlRequest
                                  token:(xRequstToken *)token
                           toRetryTimes:(NSInteger)retryTimes
                               progress:(xNetworkResposeProgress)progress
                             completion:(void(^)(xNetworkResponse *  response))completion{
    xRequestType * requestType = [xRequestType data];
    if ([requestConvertable respondsToSelector:@selector(requestType)]) {
        requestType = [requestConvertable requestType];
    }
    xAFDataTaskCompletionBlock dataCompletion = ^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        BEGIN_ASYNC_MANAGER_QUEUE
        for (id<xNetworkPlugin> plugin in self.plugins) {
            if ([plugin respondsToSelector:@selector(didReceiveResponse:responseObject:filePath:error:)]) {
                [plugin didReceiveResponse:response responseObject:responseObject filePath:nil error:error];
            }
        }
        if (token.isCanceled) {
            NSError * error = [NSError errorWithDomain:xNetworkErrorDomain
                                                  code:xNetworkErrorCanceled
                                              userInfo:nil];
            [self envokeCompletion:completion withError:error request:requestConvertable];
            return;
        }
        if (retryTimes > 0 && error) {
            [self startTaskWithRequestConvertable:requestConvertable
                                       urlRequest:urlRequest
                                            token:token
                                     toRetryTimes:(retryTimes - 1)
                                         progress:progress
                                       completion:completion];
            return;
        }
        //保存数据
        if ([requestConvertable respondsToSelector:@selector(durationForReturnCache)] && !error) {
            NSTimeInterval duration = [requestConvertable durationForReturnCache];
            if (duration > 0) {
                [xNetworkCache saveCache:responseObject
                               forRequset:urlRequest
                             httpResponse:response
                                   expire:duration];
            }
        }
        xNetworkResponse * networkResponse = [[xNetworkResponse alloc] initWithRequest:requestConvertable
                                                                             urlResponse:response
                                                                            responseData:responseObject
                                                                                   error:error];
        if(self.trackRepeatRequest){
            [self.lock lock];
            NSString * requestID = urlRequest.x_unqiueIdentifier;
            NSArray * callBacks = [self.callbackMap objectForKey:requestID];
            for (xNetworkResposeComplete callback in callBacks) {
                [self envokeCallBack:callback withResponse:networkResponse requestConvertable:requestConvertable];
            }
            [self.callbackMap removeObjectForKey:requestID];
            [self.lock unlock];
        }else{
            [self envokeCallBack:completion withResponse:networkResponse requestConvertable:requestConvertable];
        }
        END_ASYNC_MANAGER_QUEU
    };
    if ([requestType isKindOfClass:[xRequestTypeDownlaod class]]) {//下载任务
        xRequestTypeDownlaod * download = (xRequestTypeDownlaod *)requestType;
        
        xAFDownloadTaskCompletionBlock downloadCompletion = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            BEGIN_ASYNC_MANAGER_QUEUE
            for (id<xNetworkPlugin> plugin in self.plugins) {
                if ([plugin respondsToSelector:@selector(didReceiveResponse:responseObject:filePath:error:)]) {
                    [plugin didReceiveResponse:response responseObject:nil filePath:filePath error:error];
                }
            }
            if (token.isCanceled) {
                NSError * error = [NSError errorWithDomain:xNetworkErrorDomain
                                                      code:xNetworkErrorCanceled
                                                  userInfo:nil];
                [self envokeCompletion:completion withError:error request:requestConvertable];
                return;
            }
            if (retryTimes > 0 && error) {
                [self startTaskWithRequestConvertable:requestConvertable
                                           urlRequest:urlRequest
                                                token:token
                                         toRetryTimes:(retryTimes - 1)
                                             progress:progress
                                           completion:completion];
                return;
            }
            xNetworkResponse * networkResponse = [[xNetworkResponse alloc] initWithRequest:requestConvertable
                                                                                 urlResponse:response
                                                                                    filePath:filePath
                                                                                       error:error];
            if(self.trackRepeatRequest){
                [self.lock lock];
                NSString * requestID = urlRequest.x_unqiueIdentifier;
                NSArray * callBacks = [self.callbackMap objectForKey:requestID];
                for (xNetworkResposeComplete callback in callBacks) {
                    [self envokeCallBack:callback withResponse:networkResponse requestConvertable:requestConvertable];
                }
                [self.callbackMap removeObjectForKey:requestID];
                [self.lock unlock];
            }else{
                [self envokeCallBack:completion withResponse:networkResponse requestConvertable:requestConvertable];
            }
            END_ASYNC_MANAGER_QUEU
        };
        NSURLSessionDownloadTask * task;
        if (!download.resumeData) {
            task = [self.afSessionManager downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
                *progress = downloadProgress;
            } destination:download.destionation completionHandler:downloadCompletion];

        }else{
            task = [self.afSessionManager downloadTaskWithResumeData:download.resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
                *progress = downloadProgress;
            } destination:download.destionation completionHandler:downloadCompletion];
        }
        token.task = task;
        [task resume];
    }else if ([requestConvertable isKindOfClass:[xRequestTypeUpload class]]) {//上传任务
        xRequestTypeUpload * upload = (xRequestTypeUpload *)requestConvertable.requestType;
        NSURLSessionUploadTask * task;
        if (upload.data) {
            task = [self.afSessionManager uploadTaskWithRequest:urlRequest fromData:upload.data progress:^(NSProgress * _Nonnull uploadProgress) {
                *progress = uploadProgress;
            } completionHandler:dataCompletion];
        }else if(!upload.isMultiPartFormData){
            task = [self.afSessionManager uploadTaskWithRequest:urlRequest fromFile:upload.fileURL progress:^(NSProgress * _Nonnull uploadProgress) {
                *progress = uploadProgress;
            } completionHandler:dataCompletion];
        }else{
            task = [self.afSessionManager uploadTaskWithStreamedRequest:urlRequest progress:^(NSProgress * _Nonnull uploadProgress) {
                *progress = uploadProgress;
            } completionHandler:dataCompletion];
        }

        token.task = task;
        [task resume];
    }else{

        NSURLSessionDataTask * task = [self.afSessionManager dataTaskWithRequest:urlRequest uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
            
        } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
            
        } completionHandler:dataCompletion];
        token.task = task;
        [task resume];
    }

}
@end

