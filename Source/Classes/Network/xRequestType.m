

#import "xRequestType.h"

@interface xRequestTypeUpload()

@property (assign, nonatomic, readwrite) BOOL isMultiPartFormData;

@property (copy, nonatomic, readwrite)void (^constructingBodyBlock)(id <AFMultipartFormData> formData);

@property (strong, nonatomic, readwrite) NSURL * fileURL;

@property (strong, nonatomic, readwrite) NSData * data;

@end

@implementation xRequestTypeUpload

- (instancetype)initWithFileURL:(NSURL *)fileURL{
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.isMultiPartFormData = NO;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data{
    if (self = [super init]) {
        self.data = data;
        self.isMultiPartFormData = NO;
    }
    return self;
}
@end

@interface xRequestTypeDownlaod()

@property (strong, nonatomic, readwrite) NSData * resumeData;

@property (strong, nonatomic, readwrite) xNetworkResponseDownlaodDestination destionation;

@end

@implementation xRequestTypeDownlaod

- (instancetype)initWithResumeData:(NSData *)data destionation:(xNetworkResponseDownlaodDestination)destionation{
    if (self = [super init]) {
        self.resumeData = data;
        self.destionation = destionation;
    }
    return self;
}

@end

@implementation xRequestType

+ (instancetype)data{
    return [[xRequestType alloc] init];
}

+ (instancetype)uploadFromData:(NSData *)data{
    return (xRequestType *)[[xRequestTypeUpload alloc] initWithData:data];
}

+ (instancetype)uploadFromFileURL:(NSURL *)fileURL{
    return (xRequestType *)[[xRequestTypeUpload alloc] initWithFileURL:fileURL];
}

+ (instancetype)downlaodWithDestination:(xNetworkResponseDownlaodDestination)destination{
    return (xRequestType *)[[xRequestTypeDownlaod alloc] initWithResumeData:nil
                                                                 destionation:destination];
}

+ (instancetype)downloadWithResumeData:(NSData *)resumeData destination:(xNetworkResponseDownlaodDestination)destination{
    return (xRequestType *)[[xRequestTypeDownlaod alloc] initWithResumeData:resumeData
                                                                 destionation:destination];
}


+ (instancetype)uploadWithMultipartFormConstructingBodyBlock:(void (^)(id<AFMultipartFormData> _Nonnull))block{
    xRequestTypeUpload * type =  [[xRequestTypeUpload alloc] init];
    type.constructingBodyBlock = block;
    type.isMultiPartFormData = YES;
    return type;
}
@end

