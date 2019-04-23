//
//  GCDTimer.m
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/22.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//

#import "GCDTimer.h"

#define kSetNil(obj) do {if (obj) {obj = nil;}}while(0);

@interface GCDTimer ()

@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation GCDTimer

/**
 dispatch_source_t的实现定时器, 时间间隔1s, 无限循环

 @param intervalBlock   每个时间间隔的回调
 @return                GCDTimer对象，可管理定时器状态，对其取消、暂停与恢复
 */
+ (instancetype)timerWithIntervalBlock:(intervalBlock)intervalBlock {
    return [GCDTimer timerWithInterval:1.0f repeats:NSIntegerMax intervalBlock:intervalBlock completeBlock:nil];
}

/**
 dispatch_source_t的实现定时器, 无限循环

 @param interval        定时器间隔
 @param intervalBlock   每个时间间隔的回调
 @return                GCDTimer对象，可管理定时器状态，对其取消、暂停与恢复
 */
+ (instancetype)timerWithInterval:(CGFloat)interval intervalBlock:(intervalBlock)intervalBlock {
    return [GCDTimer timerWithInterval:interval repeats:NSIntegerMax intervalBlock:intervalBlock completeBlock:nil];
}

/**
 dispatch_source_t的实现定时器，每次间隔和定时完成均通过block回调

 @param interval        定时器间隔
 @param repeats         重复次数，0表示不重复，
 @param intervalBlock   每个时间间隔的回调
 @param completeBlock   完成后回调
 @return                GCDTimer对象，可管理定时器状态，对其取消、暂停与恢复
 */
+ (instancetype)timerWithInterval:(CGFloat)interval repeats:(NSInteger)repeats intervalBlock:(intervalBlock)intervalBlock completeBlock:(dispatch_block_t __nullable)completeBlock {

    // __block
    __block NSInteger count = repeats;

    /**
     生成一个dispatch source对象

     type    dispatch source对象的使用类型，这里是定时器类型：DISPATCH_SOURCE_TYPE_TIMER
     handle  传0
     mask    传0
     queue   线程，一般传全局异步线程
     */
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    // 设置定时器属性，第一个参数是定时器对象，第二个是定时器开始执行时，延时的时间，第三个是定时器的间隔，第四个是定时器的精度误差
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    // 设置定时器的回调函数
    dispatch_source_set_event_handler(timer, ^{
        // 记录剩余循环次数
        count--;

        if (count <= 0) {
            // 取消定时器
            dispatch_source_cancel(timer);
            // 回到主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                // 执行完成回调
                completeBlock();
            });
        } else {
            // 回到主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                // 执行定时器回调，参数表示执行次数，从1开始
                intervalBlock(repeats - count);
            });
        }
    });
    // 开始执行
    dispatch_resume(timer);

    // 生成一个实例对象
    GCDTimer * gcdTimer = [GCDTimer new];
    // 对dispatch_source_t的实例对象timer做一个强引用，不然timer会被释放，定时器就无法执行
    gcdTimer.timer = timer;
    // 返回实例对象
    return gcdTimer;
}

/**
 取消定时器
 */
- (void)cancel {
    if (_timer) {
        dispatch_source_cancel(_timer);
        NSLog(@"取消定时器");
        kSetNil(_timer);
    } else {
        NSLog(@"warning: 定时器已被释放");
    }

}

/**
 暂停定时器
 */
- (void)suspend {
    if (_timer) {
        dispatch_suspend(_timer);
        NSLog(@"暂停定时器");
    } else {
        NSLog(@"warning: 定时器已被释放");
    }
}

/**
 恢复定时器
 */
- (void)resume {
    if (_timer) {
        dispatch_resume(_timer);
        NSLog(@"恢复定时器");
    } else {
        NSLog(@"warning: 定时器已被释放");
    }
}

@end
