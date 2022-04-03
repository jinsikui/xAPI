

#import "xAPI.h"

@interface xAPIBaseBuilder ()
@property (nonatomic, copy, nullable, readwrite) SAPISetParamsBlock paramsBlock;
@property (nonatomic, copy, nullable, readwrite) SAPISetHeadersBlock headersBlock;
@property (nonatomic, copy) NSString *mDefaultHost;
@property (nonatomic, assign) xHTTPMethod mDefaultMethod;
@end

@implementation xAPIBaseBuilder

+ (instancetype)shared {
    static xAPIBaseBuilder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[xAPIBaseBuilder alloc] init];
    });
    return instance;
}

- (void (^)(SAPISetParamsBlock _Nonnull))commonParams {
    return ^(SAPISetParamsBlock commonParamsBlock) {
        self.paramsBlock = commonParamsBlock;
    };
}

- (void (^)(SAPISetHeadersBlock _Nonnull))commonHeaders {
    return ^(SAPISetHeadersBlock commonHeadersBlock) {
        self.headersBlock = commonHeadersBlock;
    };
}

- (void (^)(NSString *defaultHost))defaultHost {
    return ^(NSString *defaultHost) {
        self.mDefaultHost = [defaultHost copy];
    };
}

- (void (^)(xHTTPMethod defaultMethod))defaultMethod {
    return ^(xHTTPMethod defaultMethod) {
        self.mDefaultMethod = defaultMethod;
    };
}

@end

@interface xAPIConvertable () {
    NSDictionary *_mParams;
    NSDictionary *_mHeaders;
    NSString *_mHost;
    NSString *_mPath;
    xHTTPMethod _mMethod;
    xParameterEncoding _mEncodingType;
    xResponseDecncoding _mDecodingType;
    xNetworkSub *_mStubData;
}
@end
@implementation xAPIConvertable

- (instancetype)initWithParams:(NSDictionary *)params
                       headers:(NSDictionary *)headers
                          host:(NSString *)host
                          path:(NSString *)path
                        method:(xHTTPMethod)method
                  encodingType:(xParameterEncoding)encodingType
                  decodingType:(xResponseDecncoding)decodingType
                      stubData:(xNetworkSub*)stubData{
    self = [super init];
    if (self) {
        _mParams = params;
        _mHeaders = headers;
        _mHost = host;
        _mPath = path;
        _mMethod = method;
        _mEncodingType = encodingType;
        _mDecodingType = decodingType;
        _mStubData = stubData;
    }
    return self;
}

#pragma mark - xNetworkConvertable
- (NSString*)baseURL {
    return _mHost;
}

- (NSDictionary<NSString *,NSString *> *)httpHeaders {
    return _mHeaders;
}

- (NSString *)path {
    return _mPath;
}

- (xHTTPMethod)httpMethod {
    return _mMethod;
}

- (NSDictionary *)parameters {
    return _mParams;
}

- (xParameterEncoding)encodingType {
    return _mEncodingType;
}

- (xResponseDecncoding)decodingType {
    return _mDecodingType;
}

- (xNetworkSub*)stubData{
    return _mStubData;
}

- (xNetworkResponse *)adaptResponse:(xNetworkResponse *)networkResponse {
    return [[xNetworkResponse alloc] initWithResponse:networkResponse adpatedObject:networkResponse.responseObject];
}

@end

@interface xAPIBuilder ()

@property (nonatomic, copy, readwrite) NSString *mTag;
@property (nonatomic, strong, readwrite) xNetworkSub *mStubData;
@property (nonatomic, strong, readwrite) NSDictionary *mParams;
@property (nonatomic, strong, readwrite) NSDictionary *mHeaders;
@property (nonatomic, assign, readwrite) xAPICommonParamsUsage mParamUsage;
@property (nonatomic, assign, readwrite) xAPICommonHeadersUsage mHeaderUsage;
@property (nonatomic, copy, readwrite) NSString *mHost;
@property (nonatomic, copy, readwrite) NSString *mPath;
@property (nonatomic, assign, readwrite) xHTTPMethod mMethod;
@property (nonatomic, assign, readwrite) xParameterEncoding mEncodingType;
@property (nonatomic, assign, readwrite) xResponseDecncoding mDecodingType;
@property (nonatomic, copy, nullable, readwrite) SAPIBeforeNetworkCallbackBlock beforeCallback;

@property (strong, nonatomic) xNetworkManager * manager;
@end

@implementation xAPIBuilder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.manager = [xNetworkManager manager];
        self.mEncodingType = xParameterEncodingJSON;
        self.mDecodingType = xResponseDecncodingJSON;
        self.mParamUsage = xAPICommonParamsUsagePath;
        self.mHeaderUsage = xAPICommonHeadersUsageHeaders;
        self.mMethod = [xAPIBaseBuilder shared].mDefaultMethod;
        self.mHost = [xAPIBaseBuilder shared].mDefaultHost;
    }
    return self;
}

- (xAPIBuilder * _Nonnull (^)(NSString * _Nonnull))tag {
    return ^id(NSString *tag) {
        self.mTag = tag;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(xNetworkSub * _Nonnull))stubData {
    return ^id(xNetworkSub *stubData) {
        self.mStubData = stubData;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(NSDictionary * _Nonnull))params {
    return ^id(NSDictionary *params) {
        self.mParams = params;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(NSDictionary * _Nonnull))headers {
    return ^id(NSDictionary *headers) {
        self.mHeaders = headers;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(xAPICommonParamsUsage))commonParamsUsage {
    return ^id(xAPICommonParamsUsage usage) {
        self.mParamUsage = usage;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(xAPICommonHeadersUsage))commonHeadersUsage {
    return ^id(xAPICommonHeadersUsage usage) {
        self.mHeaderUsage = usage;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(NSString * _Nonnull))host {
    return ^id(NSString *host) {
        self.mHost = [host copy];
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(NSString * _Nonnull))path {
    return ^id(NSString *path) {
        self.mPath = [path copy];
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(xHTTPMethod))method {
    return ^id(xHTTPMethod method) {
        self.mMethod = method;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(xParameterEncoding))encodingType {
    return ^id(xParameterEncoding encodingType) {
        self.mEncodingType = encodingType;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(xResponseDecncoding))decodingType {
    return ^id(xResponseDecncoding decodingType) {
        self.mDecodingType = decodingType;
        return self;
    };
}

- (xAPIBuilder * _Nonnull (^)(SAPIBeforeNetworkCallbackBlock _Nonnull))beforeNetworkCallback {
    return ^id(SAPIBeforeNetworkCallbackBlock beforeCallback) {
        self.beforeCallback = beforeCallback;
        return self;
    };
}

- (FBLPromise * (^)(void))execute {
    return ^FBLPromise * {
        FBLPromise * (^networkPromise)(void) = ^{
            return FBLPromise.asyncOn(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(FBLPromiseFulfillBlock fulfill, FBLPromiseRejectBlock reject) {
                void (^myCompletion)(xNetworkResponse * _Nonnull, NSInteger, NSString*) = ^(xNetworkResponse * _Nonnull response, NSInteger errorCode, NSString *errorMsg) {
                    if (errorCode != 0) {
                        NSError *error = [NSError errorWithDomain:xAPIErrorDomain code:errorCode userInfo:@{xAPIErrorMessageKey: errorMsg ?: @""}];
                        reject(error);
                    } else {
                        fulfill(response.responseObject);
                    }
                };
                [self.manager request:[self createConvertable] completion:[self getRequestCompletionFromCompletion:myCompletion]];
            });
        };
        /// 是否有在网络请求之前的回调
        if (self.beforeCallback) {
            FBLPromise *beforePromise = self.beforeCallback();
            if (beforePromise) {
                return beforePromise.then(^id _Nullable(id  _Nullable value) {
                    return networkPromise();
                });
            }
        }
        return networkPromise();
    };
}

- (xAPIConvertable *)createConvertable {
    NSMutableDictionary *commonParams = [NSMutableDictionary dictionary];
    if ([xAPIBaseBuilder shared].paramsBlock) {
        commonParams = [[xAPIBaseBuilder shared].paramsBlock(self.mTag) mutableCopy];
    }
    NSMutableDictionary *commonHeaders = [NSMutableDictionary dictionary];
    if ([xAPIBaseBuilder shared].headersBlock) {
        commonHeaders = [[xAPIBaseBuilder shared].headersBlock(self.mTag) mutableCopy];
    }
    /// 参数
    if (self.mParamUsage & xAPICommonParamsUsageParams) {
        [commonParams addEntriesFromDictionary:self.mParams];
        self.mParams = commonParams;
    }
    /// 头
    if (self.mHeaderUsage & xAPICommonHeadersUsageHeaders) {
        [commonHeaders addEntriesFromDictionary:self.mHeaders];
        self.mHeaders = commonHeaders;
    }
    /// 地址
    if (self.mParamUsage & xAPICommonParamsUsagePath) {
        self.mPath = [xAPIHelper mergeToInput:self.mPath queryParams:commonParams];
    }
    
    /// 编码
    xParameterEncoding encodingType = self.mMethod == HTTP_GET ? xParameterEncodingHTTP : self.mEncodingType;
    
    return [[xAPIConvertable alloc] initWithParams:self.mParams
                                           headers:self.mHeaders
                                              host:self.mHost
                                              path:self.mPath
                                            method:self.mMethod
                                      encodingType:encodingType
                                      decodingType:self.mDecodingType
                                          stubData:self.mStubData];
}

- (void(^)(xNetworkResponse * _Nonnull))getRequestCompletionFromCompletion:(void (^)(xNetworkResponse * _Nonnull, NSInteger errorCode, NSString *errorMsg))completion {
    void (^requestCompletion)(xNetworkResponse * _Nonnull) = ^(xNetworkResponse *response) {
        NSInteger errorCode = 0;
        NSString *errorMsg = nil;
        if (response.statusCode != 200) {
            errorCode = response.statusCode > 0 ? response.statusCode : 110; /*110代表请求超时*/
        }
        if ([response.responseObject isKindOfClass:NSDictionary.class]) {
            NSDictionary *body = response.responseObject;
            if (xapi_not_null(body[@"errcode"]) || xapi_not_null(body[@"code"]) || xapi_not_null(body[@"errorno"]) || xapi_not_null(body[@"errCode"])) {
                //code not null
                NSInteger code = xapi_not_null(body[@"errcode"]) ? [body[@"errcode"] integerValue] : xapi_not_null(body[@"code"]) ? [body[@"code"] integerValue] : xapi_not_null(body[@"errorno"]) ?  [body[@"errorno"] integerValue] : [body[@"errCode"] integerValue];
                if (code != 200 && code != 0) {
                    errorCode = code;
                }
            }
            errorMsg = xapi_not_null(body[@"errmsg"]) ? body[@"errmsg"] : xapi_not_null(body[@"msg"]) ? body[@"msg"] : xapi_not_null(body[@"errormsg"]) ? body[@"errormsg"] : xapi_not_null(body[@"errMsg"]) ? body[@"errMsg"] : nil;
        }
        if (errorCode > 0) {
            if (completion) {
                completion(response, errorCode, errorMsg);
            }
            return;
        }
        
        if([response.responseObject isKindOfClass:NSDictionary.class]){
            NSDictionary *body = response.responseObject;
            id data = xapi_not_null(body[@"data"]) ? body[@"data"] : xapi_not_null(body[@"ret"]) ? body[@"ret"] : nil;
            if (data != nil) {
                response = [[xNetworkResponse alloc] initWithResponse:response adpatedObject:data];
            }
        }
        if (completion) {
            completion(response, errorCode, errorMsg);
        }
    };
    return requestCompletion;
}

@end

@implementation xAPI

#pragma mark - Common API Properties

+ (void)buildCommon:(void (^)(xAPIBaseBuilder * _Nonnull baseBuilder))block {
    block([xAPIBaseBuilder shared]);
}

+ (void (^)(SAPISetParamsBlock _Nonnull))commonParams {
    return xAPIBaseBuilder.shared.commonParams;
}

+ (void (^)(SAPISetHeadersBlock _Nonnull))commonHeaders {
    return xAPIBaseBuilder.shared.commonHeaders;
}

+ (void (^)(NSString * _Nonnull))defaultHost {
    return xAPIBaseBuilder.shared.defaultHost;
}

+ (void (^)(xHTTPMethod))defaultMethod {
    return xAPIBaseBuilder.shared.defaultMethod;
}

#pragma mark - Instance API Properties

+ (xAPIBuilder *)build:(void (^)(xAPIBuilder * _Nonnull))block {
    xAPIBuilder *builder = [[xAPIBuilder alloc] init];
    if (block) {
        block(builder);
    }
    return builder;
}

+ (xAPIBuilder * _Nonnull (^)(NSString * _Nonnull))tag {
    return [[[xAPIBuilder alloc] init] tag];
}

+ (xAPIBuilder * _Nonnull (^)(xNetworkSub * _Nonnull))stubData {
    return [[[xAPIBuilder alloc] init] stubData];
}

+ (xAPIBuilder * _Nonnull (^)(NSDictionary * _Nonnull))params {
    return [[[xAPIBuilder alloc] init] params];
}

+ (xAPIBuilder * _Nonnull (^)(NSDictionary * _Nonnull))headers {
    return [[[xAPIBuilder alloc] init] headers];
}

+ (xAPIBuilder * _Nonnull (^)(xAPICommonParamsUsage))commonParamsUsage {
    return [[[xAPIBuilder alloc] init] commonParamsUsage];
}

+ (xAPIBuilder * _Nonnull (^)(xAPICommonHeadersUsage))commonHeadersUsage {
    return [[[xAPIBuilder alloc] init] commonHeadersUsage];
}

+ (xAPIBuilder * _Nonnull (^)(NSString * _Nonnull))host {
    return [[[xAPIBuilder alloc] init] host];
}

+ (xAPIBuilder * _Nonnull (^)(NSString * _Nonnull))path {
    return [[[xAPIBuilder alloc] init] path];
}

+ (xAPIBuilder * _Nonnull (^)(xHTTPMethod))method {
    return [[[xAPIBuilder alloc] init] method];
}

+ (xAPIBuilder * _Nonnull (^)(xParameterEncoding))encodingType {
    return [[[xAPIBuilder alloc] init] encodingType];
}

+ (xAPIBuilder * _Nonnull (^)(SAPIBeforeNetworkCallbackBlock _Nonnull))beforeNetworkCallback {
    return [[[xAPIBuilder alloc] init] beforeNetworkCallback];
}

@end
