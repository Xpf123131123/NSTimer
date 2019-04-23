//
//  GCDTimer.h
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/22.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^intervalBlock)(NSUInteger currentInterval);

@interface GCDTimer : NSObject

#pragma mark ================定时器构造方法================
/**
 无限循环的实现定时器, 默认时间间隔1.0s

 @param intervalBlock   每个时间间隔的回调
 @return                GCDTimer对象，可管理定时器状态，对其取消、暂停与恢复
 */
+ (instancetype)timerWithIntervalBlock:(intervalBlock)intervalBlock;

/**
 无限循环的实现定时器, 需要传入时间间隔, dispatch_source_t

 @param interval        定时器间隔
 @param intervalBlock   每个时间间隔的回调
 @return                GCDTimer对象，可管理定时器状态，对其取消、暂停与恢复
 */
+ (instancetype)timerWithInterval:(CGFloat)interval intervalBlock:(intervalBlock)intervalBlock;

/**
 可自定义参数的实现定时器,需要传入时间间隔，循环次数，定时回调和完成回调, dispatch_source_t

 @param interval        定时器间隔
 @param repeats         重复次数，0表示不重复，
 @param intervalBlock   每个时间间隔的回调
 @param completeBlock   完成后回调
 @return                GCDTimer对象，可管理定时器状态，对其取消、暂停与恢复
 */
+ (instancetype)timerWithInterval:(CGFloat)interval repeats:(NSInteger)repeats intervalBlock:(intervalBlock)intervalBlock completeBlock:(dispatch_block_t __nullable)completeBlock;


#pragma mark ================定时器状态================
/**
 取消定时器
 */
- (void)cancel;

/**
 暂停定时器
 */
- (void)suspend;

/**
 恢复定时器
 */
- (void)resume;

@end

NS_ASSUME_NONNULL_END
