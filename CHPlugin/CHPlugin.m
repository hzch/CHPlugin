//
//  CHPlugin.m
//  CHPlugin
//
//  Created by Jiang on 16/4/1.
//  Copyright © 2016年 hzch. All rights reserved.
//

#import "CHPlugin.h"

@implementation CHPlugin

/// 系统接口，Xcode启动时会调
+(void)pluginDidLoad:(NSBundle *)plugin {
    [self sharedInstance];
    NSLog(@"Hello World");
}

/// 保证生命周期与Xcode相同
+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self allNotification];
    }
    return self;
}

- (void)allNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationListener:)
                                                 name:nil
                                               object:nil];
}

-(void)notificationListener:(NSNotification *)noti {
    NSLog(@" Notification: %@", [noti name]);   
}

@end
