

#import "xNetworkAsyncOperation.h"

typedef NS_ENUM(NSInteger, xNetworkAsyncOperationState){
    xNetworkAsyncOperationStatePaused,
    xNetworkAsyncOperationStateReady,
    xNetworkAsyncOperationStateExecuting,
    xNetworkAsyncOperationStateFinished,
};

static inline BOOL xN_StateTransitionValid(xNetworkAsyncOperationState fromState,xNetworkAsyncOperationState toState, BOOL isCancelled){
    switch (fromState) {
        case xNetworkAsyncOperationStateReady:
            switch (toState) {
                case xNetworkAsyncOperationStatePaused:
                case xNetworkAsyncOperationStateExecuting:
                    return YES;
                case xNetworkAsyncOperationStateFinished:
                    return isCancelled;
                default:
                    return NO;
            }
        case xNetworkAsyncOperationStateExecuting:
            switch (toState) {
                case xNetworkAsyncOperationStatePaused:
                case xNetworkAsyncOperationStateFinished:
                    return YES;
                default:
                    return NO;
            }
        case xNetworkAsyncOperationStateFinished:
            return NO;
        case xNetworkAsyncOperationStatePaused:
            return toState == xNetworkAsyncOperationStateFinished || toState == xNetworkAsyncOperationStateExecuting;
    }
}

static inline NSString * xN_KeyPathForOperationState(xNetworkAsyncOperationState state){
    switch (state) {
        case xNetworkAsyncOperationStateReady:
            return @"isReady";
            break;
        case xNetworkAsyncOperationStatePaused:
            return @"isPaused";
        case xNetworkAsyncOperationStateExecuting:
            return @"isExecuting";
        
        case xNetworkAsyncOperationStateFinished:
            return @"isFinished";
    }
}


@interface xNetworkAsyncOperation()

@property (assign, nonatomic) xNetworkAsyncOperationState state;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation xNetworkAsyncOperation

- (instancetype)init{
    if (self = [super init]) {
        _lock = [[NSRecursiveLock alloc] init];
        _state = xNetworkAsyncOperationStateReady;
    }
    return self;
}
- (void)start{
    if ([self isCancelled]) {
        self.state = xNetworkAsyncOperationStateFinished;
        return;
    }
    self.state = xNetworkAsyncOperationStateExecuting;
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
}

- (void)setState:(xNetworkAsyncOperationState)state{
    if (!xN_StateTransitionValid(_state, state, [self isCancelled])) {
        return;
    }
    [self.lock lock];
    NSString * oldStateKey =  xN_KeyPathForOperationState(_state);
    NSString * newStateKey =  xN_KeyPathForOperationState(state);
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
    [self.lock unlock];
}

- (void)main{
    if ([self isCancelled]) {
        self.state = xNetworkAsyncOperationStateFinished;
        return;
    }
    [self execute];
}

#pragma mark - API

- (void)pause{
    if ([self isPaused] || [self isCancelled] || [self isFinished]) {
        return;
    }
    self.state = xNetworkAsyncOperationStatePaused;
}

- (void)resume{
    if (![self isPaused]) {
        return;
    }
    self.state = xNetworkAsyncOperationStateExecuting;
}

- (void)execute{}

- (void)finishOperation{
    self.state = xNetworkAsyncOperationStateFinished;
}

- (void)cancel{
    self.state = xNetworkAsyncOperationStateFinished;
    [super cancel];
}

#pragma mark - Life Circle

- (BOOL)isPaused {
    return self.state == xNetworkAsyncOperationStatePaused;
}

- (BOOL)isReady{
    return self.state == xNetworkAsyncOperationStateReady && [super isReady];
}

- (BOOL)isConcurrent{
    return YES;
}

- (BOOL)isFinished{
    return self.state == xNetworkAsyncOperationStateFinished;
}

- (BOOL)isExecuting{
    return self.state == xNetworkAsyncOperationStateExecuting;
}
- (BOOL)isAsynchronous{
    return YES;
}

@end
