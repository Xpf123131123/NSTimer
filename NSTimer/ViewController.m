//
//  ViewController.m
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/20.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//

#import "ViewController.h"

#import "NSTimer+Default.h"
#import "GCDTimer.h"
@interface ViewController ()
{
    dispatch_source_t timer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    GCDTimer * gcdTimer = [GCDTimer timerWithInterval:1 repeats:30 intervalBlock:^(NSUInteger currentInterval) {
//        NSLog(@"%lu", currentInterval);
//    } completeBlock:^{
//        NSLog(@"111");
//    }];

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

}




@end
