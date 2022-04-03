

#import <Foundation/Foundation.h>

@interface xNetworkAsyncOperation : NSOperation

/**
 异步调用的代码，子类重写
 */
- (void)execute;

/**
 给子类调用的完成当前operation
 */
- (void)finishOperation;

/**
 暂停任务
 */
- (void)pause;

/**
  继续任务
 */
- (void)resume;
@end
