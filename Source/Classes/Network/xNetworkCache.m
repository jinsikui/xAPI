

#import "xNetworkCache.h"
#import "NSURLRequest+xNetwork.h"

//static dispatch_queue_t snetwork_cache_queue() {
//    static dispatch_queue_t queue;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0);
//        queue = dispatch_queue_create("com.snetwork.caching", attr);
//    });
//    
//    return queue;
//}

@implementation xNetworkCacheItem

@end

@interface xNetworkCacheMetaData : NSObject<NSSecureCoding>

@property (copy, nonatomic) NSString * appVersion;

@property (strong, nonatomic) NSDate * createDate;

@property (strong, nonatomic) NSURLResponse * httpResponse;

@property (assign, nonatomic) NSTimeInterval expireDuration;

@property (assign, nonatomic, readonly) BOOL isDataExpired;
@end

@implementation xNetworkCacheMetaData

+ (BOOL)supportsSecureCoding{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self= [super init]) {
        self.appVersion = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"version"];
        self.createDate = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"createDate"];
        self.expireDuration = [aDecoder decodeIntForKey:@"expireDuration"];
        self.httpResponse = [aDecoder decodeObjectOfClass:[NSURLResponse class] forKey:@"httpResponse"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.appVersion forKey:@"version"];
    [aCoder encodeObject:self.createDate forKey:@"createDate"];
    [aCoder encodeInt:self.expireDuration forKey:@"expireDuration"];
    [aCoder encodeObject:self.httpResponse forKey:@"httpResponse"];
}

- (BOOL)isDataExpired{
    return self.createDate && [[NSDate date] timeIntervalSinceDate:self.createDate] < self.expireDuration;
}
@end


@implementation xNetworkCache

+ (NSString *)networkCacheHomeDirPath{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * cachePath = [[[fm URLsForDirectory:NSCachesDirectory
                                      inDomains:NSUserDomainMask] firstObject] path];
    if (!cachePath) {//不存在cache目录
        NSString * library = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject].path;
        cachePath = [library stringByAppendingPathComponent:@"Caches"];
    }
    NSString * homeDir = [cachePath stringByAppendingPathComponent:@"xNetworkCache"];
    return homeDir;
}

+ (NSString *)metadataCacheDirPath{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * homePath = [xNetworkCache networkCacheHomeDirPath];
    NSString * metadataPath = [homePath stringByAppendingPathComponent:@"MetaData"];
    if (![fm fileExistsAtPath:metadataPath]) {
        [fm createDirectoryAtPath:metadataPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return metadataPath;
}

+ (NSString *)dataCacheDirPath{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * homePath = [xNetworkCache networkCacheHomeDirPath];
    NSString * metadataPath = [homePath stringByAppendingPathComponent:@"Data"];
    if (![fm fileExistsAtPath:metadataPath]) {
        [fm createDirectoryAtPath:metadataPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return metadataPath;
}

+ (void)saveCache:(NSData *)data
       forRequset:(NSURLRequest *)urlRequst
     httpResponse:(NSURLResponse*)httpResponse
           expire:(NSTimeInterval)expire{
        xNetworkCacheMetaData * metaData= [[xNetworkCacheMetaData alloc] init];
        metaData.appVersion = [NSString stringWithFormat:@"%@",
                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        metaData.createDate = [NSDate date];
        metaData.expireDuration = expire;
        metaData.httpResponse = httpResponse;
        [self _saveMetaData:metaData forKey:urlRequst.x_unqiueIdentifier];
        [self _saveCacheData:data forKey:urlRequst.x_unqiueIdentifier];
}

+ (xNetworkCacheItem *)cachedDataForRequest:(NSURLRequest *)urlRequst expire:(NSTimeInterval)expire{
    xNetworkCacheMetaData * metaData = [self _cachedMetaDataForkey:urlRequst.x_unqiueIdentifier];
    if (!metaData || !metaData.createDate || !metaData.httpResponse) {
        return nil;
    }
    BOOL hasExpired = [[NSDate date] timeIntervalSinceDate:metaData.createDate] > expire;
    if (hasExpired) {
        return nil;
    }
    NSData * cachedData = [self _cachedDataForKey:urlRequst.x_unqiueIdentifier];
    xNetworkCacheItem * item = [[xNetworkCacheItem alloc] init];
    item.data = cachedData;
    item.httpResponse = metaData.httpResponse;
    return item;
}

+ (void)_saveMetaData:(xNetworkCacheMetaData *)metadata forKey:(NSString *)key{
    NSString * filePath = [[xNetworkCache metadataCacheDirPath] stringByAppendingPathComponent:key];
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:metadata];
    [data writeToFile:filePath atomically:YES];
}

+ (xNetworkCacheMetaData *)_cachedMetaDataForkey:(NSString *)key{
    NSString * filePath = [[xNetworkCache metadataCacheDirPath] stringByAppendingPathComponent:key];
    NSData * data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        return nil;
    }
    xNetworkCacheMetaData * metaData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return metaData;
}

+ (void)_saveCacheData:(NSData *)data forKey:(NSString *)key{
    NSString * filePath = [[xNetworkCache dataCacheDirPath] stringByAppendingPathComponent:key];
    [data writeToFile:filePath atomically:YES];
}

+ (NSData *)_cachedDataForKey:(NSString *)key{
    NSString * filePath = [[xNetworkCache dataCacheDirPath] stringByAppendingPathComponent:key];
    return [NSData dataWithContentsOfFile:filePath];
}

+ (void)clearAllCachedFiles{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * homePath = [xNetworkCache networkCacheHomeDirPath];
    if ([fm fileExistsAtPath:homePath]) {
        [fm removeItemAtPath:homePath error:nil];
    }
}

+(NSString *)sizeOfFolder:(NSString *)folderPath
{
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }    
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    return folderSizeStr;
}

+ (NSString *)cachedSize{
    return [self sizeOfFolder:[self networkCacheHomeDirPath]];
}

+ (void)clearExpireCachedData{
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * metaDataPath = [xNetworkCache metadataCacheDirPath];
    if (![fm fileExistsAtPath:metaDataPath]) {
        NSString * cachedDataPath = [xNetworkCache dataCacheDirPath];
        if ([fm fileExistsAtPath:cachedDataPath]) {
            [fm removeItemAtPath:cachedDataPath error:nil];
        }
        return;
    }
    //遍历MetaData，然后删除
    NSError * error;
    NSArray * metaDataArray = [fm contentsOfDirectoryAtPath:metaDataPath error:&error];
    if (error || metaDataArray == nil) {
        NSString * cachedDataPath = [xNetworkCache dataCacheDirPath];
        if ([fm fileExistsAtPath:cachedDataPath]) {
            [fm removeItemAtPath:cachedDataPath error:nil];
        }
        return;
    }
    for (NSString * metaDataName in metaDataArray) {
        @autoreleasepool {
            xNetworkCacheMetaData * metaData = [self _cachedMetaDataForkey:metaDataName];
            if (metaData.isDataExpired) {
                NSString * dataPath = [[self dataCacheDirPath] stringByAppendingPathComponent:metaDataName];
                if ([fm fileExistsAtPath:dataPath]) {
                    [fm removeItemAtPath:dataPath error:nil];
                }
            }
        }
    }
}
@end

