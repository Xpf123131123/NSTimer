//
//  ViewController.m
//  NSTimer
//
//  Created by 鹏飞许 on 2019/4/20.
//  Copyright © 2019年 鹏飞许. All rights reserved.
//

#import "ViewController.h"

#import "NSTimer+Default.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [NSTimer defaultScheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"%@", timer.fireDate);
    }];

}


@end
