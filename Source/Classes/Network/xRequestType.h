

#import <Foundation/Foundation.h>

@protocol AFMultipartFormData;

NS_ASSUME_NONNULL_BEGIN

typedef NSURL *_Nonnull(^xNetworkResponseDownlaodDestination)(NSURL *targetPath, NSURLResponse *response);

/**
 标示请求的类型
 */
@interface xRequestType : NSObject

/**
 拉数据到内存
 */
+ (instancetype)data;

/**
 上传文件
 */
+ (instancetype)uploadFromFileURL:(NSURL *)fileURL;

/**
 MultipartForm类型的Upload
 */
+ (instancetype)uploadWithMultipartFormConstructingBodyBlock:(void (^)(id <AFMultipartFormData> formData))block;
/**
  上传NSData
 */
+ (instancetype)uploadFromData:(NSData *)data;


/**
 下载到路径，要在sNetworkResponseDownlaodDestination代码块中返回想要存储文件的URL地址
 */
+ (instancetype)downlaodWithDestination:(xNetworkResponseDownlaodDestination)destination;


/**
 断点续传，要在sNetworkResponseDownlaodDestination代码块中返回想要存储文件的URL地址
 */
+ (instancetype)downloadWithResumeData:(NSData *)resumeData
                           destination:(xNetworkResponseDownlaodDestination)destination;


@end

@interface xRequestTypeUpload : xRequestType

@property (strong, nonatomic, readonly) NSURL * fileURL;

@property (strong, nonatomic, readonly) NSData * data;

@property (copy, nonatomic, readonly)void (^constructingBodyBlock)(id <AFMultipartFormData> formData);

@property (assign, nonatomic, readonly) BOOL isMultiPartFormData;

@end

@interface xRequestTypeDownlaod : xRequestType

@property (strong, nonatomic, readonly) NSData * resumeData;

@property (strong, nonatomic, readonly) xNetworkResponseDownlaodDestination destionation;

@end


NS_ASSUME_NONNULL_END
