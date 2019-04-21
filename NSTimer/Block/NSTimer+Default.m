//
//  NSTimer+Default.m
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/20.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//

#import "NSTimer+Default.h"

@implementation NSTimer (Default)
/**
 封装NSTimer，解决NSTimer强引用问题，回调方法使用block

 @param interval 时间间隔
 @param repeats 是否循环
 @param block 回调方法
 @return NSTimer实例
 */
+ (NSTimer *)defaultScheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * timer))block {

    // 系统方法
    // 此处的self是NSTimer类对象
    NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timerClock:) userInfo:[block copy] repeats:repeats];
    // 返回
    return timer;
}
/**
 封装NSTimer，解决NSTimer强引用问题，解决NSTimer滑动时失效问题, 回调方法使用block

 @param interval 时间间隔
 @param repeats 是否循环
 @param block 回调方法
 @return NSTimer实例
 */
+ (NSTimer *)defaultTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * _Nonnull))block {

    // 系统方法
    NSTimer * timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(timerClock:) userInfo:[block copy] repeats:repeats];
    // 避免出现滑动时，timer失效的问题
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    // 返回
    return timer;
}

+ (void)timerClock:(NSTimer *)timer {
    void (^block)(NSTimer * timer) = timer.userInfo;
    block(timer);
}

@end
