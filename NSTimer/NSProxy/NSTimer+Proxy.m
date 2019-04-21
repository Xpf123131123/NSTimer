//
//  NSTimer+Proxy.m
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/21.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//

#import "NSTimer+Proxy.h"

@interface KPrivateTimerProxy : NSProxy
// 弱引用，对象销毁时自动释放
@property (weak, nonatomic) id target;

+ (instancetype)proxyWithTarget:(id)target;

@end

@implementation KPrivateTimerProxy

+ (instancetype)proxyWithTarget:(id)target {
    // NSProxy没有init方法
    KPrivateTimerProxy * proxy = [[self class] alloc];
    proxy.target = target;
    return proxy;
}

// 查询proxy及其父类一直到基类的方法列表，查询不到会进行消息转发
- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = [invocation selector];

    if ([self.target respondsToSelector:sel]) {
        [invocation invokeWithTarget:self.target];
    }
}

// 消息转发之前会对消息进行签名
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

@end

@implementation NSTimer (Proxy)

/**
 解决强引用问题

 @param ti          时间间隔
 @param aTarget     响应对象
 @param aSelector   响应对象的响应方法
 @param userInfo    响应时timer携带的信息
 @param yesOrNo     是否循环

 @return            timer对象
 */
+ (NSTimer *)proxyScheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo{

    // 将timer添加到默认的RunLoopDefaultMode, 滑动时会失效
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:ti
                                                      target:[KPrivateTimerProxy proxyWithTarget: aTarget]
                                                    selector:aSelector
                                                    userInfo:userInfo
                                                     repeats:yesOrNo];

    return timer;
}

/**
 解决强引用问题，同时解决滑动时timer失效问题

 @param ti          时间间隔
 @param aTarget     响应对象
 @param aSelector   响应对象的响应方法
 @param userInfo    响应时timer携带的信息
 @param yesOrNo     是否循环

 @return            timer对象
 */
+ (NSTimer *)proxyTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)yesOrNo{

    NSTimer * timer = [NSTimer timerWithTimeInterval:ti
                                          target:[KPrivateTimerProxy proxyWithTarget:aTarget]
                                        selector:aSelector
                                        userInfo:userInfo
                                         repeats:yesOrNo];

    // 将timer添加到runloop的CommonMode，解决滑动失效问题
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

    return timer;
}

@end
