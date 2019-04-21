//
//  NSTimer+Default.h
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/20.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (Default)

/**
 解决NSTimer强引用问题, 回调方法使用block

 @param interval    时间间隔
 @param repeats     是否循环
 @param block       回调方法

 @return            NSTimer实例
 */
+ (NSTimer *)defaultScheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * timer))block;


/**
 解决NSTimer强引用问题，解决NSTimer在滑动时失效问题, 回调方法使用block

 @param interval    时间间隔
 @param repeats     是否循环
 @param block       回调方法

 @return            NSTimer实例
 */
+ (NSTimer *)defaultTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer * timer))block;

@end

NS_ASSUME_NONNULL_END
