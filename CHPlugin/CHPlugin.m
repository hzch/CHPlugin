//
//  CHPlugin.m
//  CHPlugin
//
//  Created by Jiang on 16/4/1.
//  Copyright © 2016年 hzch. All rights reserved.
//

#import "CHPlugin.h"

static NSString * const kCHPluginsMenuTitle = @"Plugins";

@interface CHPlugin ()
@property (nonatomic) NSMenuItem *pluginsMenuItem;

@end

@implementation CHPlugin

/// 系统接口，Xcode启动时会调
+(void)pluginDidLoad:(NSBundle *)plugin
{
    [self sharedInstance];
}

/// 保证生命周期与Xcode相同
+ (instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    [self addPluginMenu];
}

#pragma mark - Plugin menu
- (void)addPluginMenu
{
    NSMenuItem* menuItem = [NSMenuItem new];
    menuItem.title = @"test";
    menuItem.target = self;
    menuItem.action = @selector(test);
    [self.pluginsMenuItem.submenu addItem:menuItem];
}

- (void)test
{
    NSLog(@"test");
    
}

#pragma mark - all notification
- (void)allNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationListener:)
                                                 name:nil
                                               object:nil];
}

-(void)notificationListener:(NSNotification *)noti
{
    NSLog(@" Notification: %@", [noti name]);   
}

#pragma mark - setter & getter
- (NSMenuItem *)pluginsMenuItem
{
    if (_pluginsMenuItem != nil) {
        return _pluginsMenuItem;
    }
    
    NSMenu *mainMenu = [NSApp mainMenu];
    _pluginsMenuItem = [mainMenu itemWithTitle:kCHPluginsMenuTitle];
    if (!_pluginsMenuItem) {
        _pluginsMenuItem = [[NSMenuItem alloc] init];
        _pluginsMenuItem.title = kCHPluginsMenuTitle;
        _pluginsMenuItem.submenu = [[NSMenu alloc] initWithTitle:kCHPluginsMenuTitle];
        [mainMenu addItem:_pluginsMenuItem];
    }
    return _pluginsMenuItem;
}

@end
