//
//  NSTimer+Proxy.h
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/21.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//


/*
 **具体实现原理请参考 -> iOS的消息处理及消息转发**

 建立一个proxy类，让timer强引用这个实例，
 这个类中对timer的使用者target采用弱引用的方式，
 再把需要执行的方法都转发给timer的使用者。

 实现流程：
 将selector方法的响应者改为kTimerProxy代理对象，回调到kTimerProxy的方法列表，
 因为kTimerProxy的方法列表里没有selector对应的方法，所以系统会提示kTimerPorxy是否需要消息转发，
 kTimerProxy将消息转发给aTarget对象
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSTimer (Proxy)


/**
 解决强引用问题，timer默认添加到NSDefaultRunLoopMode模式中，在NSTrackingRunLoopMode中timer失效
 NSTrackingRunLoopMode : 滑动模式，scrollview/tableview/collectionView)

 @param ti          时间间隔
 @param aTarget     响应对象
 @param aSelector   响应对象的响应方法
 @param userInfo    响应时timer携带的信息
 @param yesOrNo     是否循环

 @return            timer对象
 */
+ (NSTimer *)proxyScheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                          target:(id)aTarget
                                        selector:(SEL)aSelector
                                        userInfo:(nullable id)userInfo
                                         repeats:(BOOL)yesOrNo;


/**
 解决强引用问题，解决滑动时timer失效问题

 @param ti          时间间隔
 @param aTarget     响应对象
 @param aSelector   响应对象的响应方法
 @param userInfo    响应时timer携带的信息
 @param yesOrNo     是否循环

 @return            timer对象
 */
+ (NSTimer *)proxyTimerWithTimeInterval:(NSTimeInterval)ti
                                 target:(id)aTarget
                               selector:(SEL)aSelector
                               userInfo:(nullable id)userInfo
                                repeats:(BOOL)yesOrNo;
@end

NS_ASSUME_NONNULL_END
