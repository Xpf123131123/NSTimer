# 补充一个使用dispatch source实现的定时器

dispatch source实现的定时器，精度比NSTimerh要高，并且可以暂停、恢复与取消

```
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
```

```
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


```

```
//    [GCDTimer timerWithIntervalBlock:^(NSUInteger currentInterval) {
//
//    }];

//    GCDTimer * gcdTimer = [GCDTimer timerWithInterval:1 intervalBlock:^(NSUInteger currentInterval) {
//        NSLog(@"%lu", currentInterval);
//    }];

    GCDTimer * gcdTimer = [GCDTimer timerWithInterval:1 repeats:30 intervalBlock:^(NSUInteger currentInterval) {
        NSLog(@"%lu", currentInterval);
    } completeBlock:^{
        NSLog(@"111");
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [gcdTimer suspend]; // 暂停
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [gcdTimer resume]; // 恢复
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [gcdTimer cancel]; // 取消
    });


```


# NSTimer

## 介绍

在xcode中，使用快捷键**command+shift+0**可以调起**Developer Documentation**

或者xcode的**导航栏** -> **help** -> **Developer Documentation**

在documentation中搜索NSTimer，可以查看NSTimer的介绍，或者看本文最后面附录。
## NSRunLoop和NSTimer
NSTimer面试经常考察的一个点，就是问为什么NSTimer在tableview滑动的时候失效，不执行，问你怎么处理。
这里要先知道NSRunLoop的一个机制，如下：
### 1.NSRunLoopMode
**队列中的任务，都只能在任务对应的RunLoopMode中运行，在DefaultMode中注册的任务，在RunLoop进入TrackingMode中时是不执行的，反之亦然。**
##### NSDefaultRunLoopMode
NSRunLoop默认状态，绝大部分的RunLoop都是在这个状态下进行的
##### UITrackingRunLoopMode
NSRunLoop滑动状态，在界面滑动的时候，由默认状态切换到此状态，滑动停止时，切换回默认状态
如UIScrollView, UITableView, UICollectionView滑动时
##### NSRunLoopCommonModes
一个Mode集合，包含了NSDefaultRunLoopMode和UITrackingRunLoopMode等多种mode

### 2.NSTimer创建方法
**先上总结，苹果文档上说(最下面有附录):**

##### 1. scheduledTimerWithTimeInterval默认添加到NSDefaultRunLoopMode中
```
scheduledTimerWithTimeInterval:invocation:repeats:
scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:
```
由`scheduledTimerWithTimeInterval`开头的类方法：方法生成的NSTimer对象，系统会自动将其添加到当前RunLoop的defaultMode中，不需要用户进行管理.

##### 2. timerWithTimeInterval需要手动添加NSRunLoopMode

```
timerWithTimeInterval:invocation:repeats: 
timerWithTimeInterval:target:selector:userInfo:repeats:
```
由`timerWithTimeInterval`开头的类方法：生成的NSTimer对象需要用户手动选择将其添加到RunLoop中进行管理。

### 3.所以此问题的原因如下：

```
未滑动时                    滑动过程中                滑动停止
NSDefaultRunLoopMode -> UITrackingRunLoopMode -> NSDefaultRunLoopMode
NSTimer可正常执行                NSTimer挂起            NSTimer继续执行
```

如果使用scheduledTimerWithTimeInterval注册的NSTimer，系统是将其添加到DefaultMode中的，在滑动的时候RunLoopMode切换到UITrackingRunLoopMode状态时，NSTimer任务挂起，定时器不执行，等到滑动停止的时候才重新执行。


解决办法呢，就是将NSTimer加入到NSRunLoopCommonModes中。

```
// 解决出现滑动时，timer失效的问题
[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
```
## NSTimer循环引用
NSTimer创建时，传入有响应对象target及响应方法selector，此时，Timer会对target有一个强引用，如果target也对timer有强引用，则会造成循环引用，导致对象无法释放。如果target不对timer强引用时，因为timer对target有强引用，所以target释放时，需要先把timer释放，而一般情况下，target销毁时，需要销毁的对象都写在target的dealloc方法内，如果timer的销毁也写在对象的dealloc方法内时，也会造成无法释放，因为释放target，需要释放timer，释放timer需要走target的dealloc方法，而target的dealloc需要等到timer释放才行，也会造成循环引用，无法释放的情况。

**解决思路的关键在于，timer和响应对象target关联太紧密，将timer和target解耦**

##### 1.timer将NSTimer类对象设置为响应对象，增加一层链路
timer持有NSTimer,NSTimer回调block

```
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

```
##### 2.使用NSProxy对象做timer的响应对象，然后在NSProxy里做消息转发
NSProxy是一个专门用来做消息转发的类

此处需要理解iOS的消息转发机制

```
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
```

## 附录

附上苹果文档原文：

```
Class
NSTimer
A timer that fires after a certain time interval has elapsed, 
sending a specified message to a target object.

Overview
Timers work in conjunction with run loops. 
Run loops maintain strong references to their timers, 
so you don’t have to maintain your own strong reference
to a timer after you have added it to a run loop.

To use a timer effectively, you should be aware of how run loops operate.
See Threading Programming Guide for more information.

A timer is not a real-time mechanism. 
If a timer’s firing time occurs during a long run loop callout 
or while the run loop is in a mode that isn't monitoring the timer,
the timer doesn't fire until the next time the run loop checks the timer. 
Therefore, the actual time at which a timer fires can be significantly later. 
See also Timer Tolerance.

NSTimer is toll-free bridged with its Core Foundation counterpart, 
CFRunLoopTimerRef. See Toll-Free Bridging for more information.

Comparing Repeating and Nonrepeating Timers
You specify whether a timer is repeating or nonrepeating at creation time. 
A nonrepeating timer fires once and then invalidates itself automatically, 
thereby preventing the timer from firing again. 
By contrast, a repeating timer fires and then reschedules itself 
on the same run loop. 
A repeating timer always schedules itself based on the scheduled firing time,
as opposed to the actual firing time. For example, if a timer is scheduled to
fire at a particular time and every 5 seconds after that, 
the scheduled firing time will always fall on the original 5-second time 
intervals, even if the actual firing time gets delayed. If the firing time is
delayed so far that it passes one or more of the scheduled firing times, the
timer is fired only once for that time period; the timer is then rescheduled, 
after firing, for the next scheduled firing time in the future.

Timer Tolerance
In iOS 7 and later and macOS 10.9 and later, 
you can specify a tolerance for a timer (tolerance). 
This flexibility in when a timer fires improves the system's 
ability to optimize for increased power savings and responsiveness. 

The timer may fire at any time between its scheduled fire date and the 
scheduled fire date plus the tolerance. The timer doesn't fire before the 
scheduled fire date. For repeating timers, the next fire date is calculated 
from the original fire date regardless of tolerance applied at individual fire 
times, to avoid drift. The default value is zero, which means no additional 
tolerance is applied. The system reserves the right to apply a small amount 
of tolerance to certain timers regardless of the value of the tolerance 
property.

As the user of the timer, you can determine the appropriate tolerance for a 
timer. A general rule, set the tolerance to at least 10% of the interval, for a 
repeating timer. Even a small amount of tolerance has significant positive 
impact on the power usage of your application. The system may enforce a maximum 
value for the tolerance.

Scheduling Timers in Run Loops
You can register a timer in only one run loop at a time, 
although it can be added to multiple run loop modes within that run loop. 
There are three ways to create a timer:

Use the scheduledTimerWithTimeInterval:invocation:repeats: or 
scheduledTimerWithTimeInterval:target:selector:userInfo:repeats: 
class method to create the timer and schedule it on the current 
run loop in the default mode.

Use the timerWithTimeInterval:invocation:repeats: or 
timerWithTimeInterval:target:selector:userInfo:repeats: 
class method to create the timer object without scheduling it on a run loop. 
(After creating it, you must add the timer to a run loop manually by calling 
the addTimer:forMode: method of the corresponding NSRunLoop object.)

Allocate the timer and initialize it using the 
initWithFireDate:interval:target:selector:userInfo:repeats: method. 
(After creating it, you must add the timer to a run loop manually by calling 
the addTimer:forMode: method of the corresponding NSRunLoop object.)

Once scheduled on a run loop, the timer fires at the specified interval until 
it is invalidated. A nonrepeating timer invalidates itself immediately after it 
fires. However, for a repeating timer, you must invalidate the timer object 
yourself by calling its invalidate method. Calling this method requests the 
removal of the timer from the current run loop; as a result, you should always 
call the invalidate method from the same thread on which the timer was 
installed. Invalidating the timer immediately disables it so that it no longer 
affects the run loop. The run loop then removes the timer (and the strong 
reference it had to the timer), either just before the invalidate method 
returns or at some later point. Once invalidated, timer objects cannot be 
reused.

After a repeating timer fires, it schedules the next firing for the nearest 
future date that is an integer multiple of the timer interval after the last 
scheduled fire date, within the specified tolerance. If the time taken to call 
out to perform a selector or invocation is longer than the specified interval, 
the timer schedules only the next firing; that is, the timer doesn't attempt to 
compensate for any missed firings that would have occurred while calling the 
specified selector or invocation.


Topics
Creating a Timer

+ scheduledTimerWithTimeInterval:repeats:block:
Creates a timer and schedules it on the current run loop in the default mode.

+ scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:
Creates a timer and schedules it on the current run loop in the default mode.

+ scheduledTimerWithTimeInterval:invocation:repeats:
Creates a new timer and schedules it on the current run loop in the default mode.

+ timerWithTimeInterval:repeats:block:
Initializes a timer object with the specified time interval and block.

+ timerWithTimeInterval:target:selector:userInfo:repeats:
Initializes a timer object with the specified object and selector.

+ timerWithTimeInterval:invocation:repeats:
Initializes a timer object with the specified invocation object.

- initWithFireDate:interval:repeats:block:
Initializes a timer for the specified date and time interval with the specified block.

- initWithFireDate:interval:target:selector:userInfo:repeats:
Initializes a timer using the specified object and selector.

Firing a Timer
- fire
Causes the timer's message to be sent to its target.

Stopping a Timer
- invalidate
Stops the timer from ever firing again and requests its removal from its run loop.

Retrieving Timer Information
valid
A Boolean value that indicates whether the timer is currently valid.
fireDate
The date at which the timer will fire.
timeInterval
The timer’s time interval, in seconds.
userInfo
The receiver's userInfo object.
Configuring Firing Tolerance
tolerance
The amount of time after the scheduled fire date that the timer may fire.

```
