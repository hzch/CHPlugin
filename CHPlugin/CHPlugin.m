//
//  CHPlugin.m
//  CHPlugin
//
//  Created by Jiang on 16/4/1.
//  Copyright © 2016年 hzch. All rights reserved.
//

#import "CHPlugin.h"

@interface NSObject (IgnoreUndefinedKey)

@end

@implementation NSObject (IgnoreUndefinedKey)

- (nullable id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

@end

static NSString * const kCHPluginsMenuTitle = @"Plugins";

@interface CHPlugin ()
@property (nonatomic) NSMenuItem *pluginsMenuItem;
@property (nonatomic) NSString *currentBundleId;
@property (nonatomic) NSString *currentDeviceAppPath;
@property (nonatomic) NSString *currentDocuments;
@property (nonatomic) NSFileManager *fileManager;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(buildWillStart:)
                                                     name:@"IDEBuildOperationWillStartNotification"
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
    menuItem.title = @"Go To Documents";
    menuItem.target = self;
    menuItem.action = @selector(test);
    [self.pluginsMenuItem.submenu addItem:menuItem];
}

- (void)test
{
    NSString *currentDocuments = self.currentDocuments;
    if (currentDocuments.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Not found documents!"];
        [alert setInformativeText:@"Please build or run with your project. If it still doesn't work, send email to jch.main@gmail.com."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        return;
    }
    
    NSString *open = [NSString stringWithFormat:@"open %@",self.currentDocuments];
    const char *str = [open UTF8String];
    system(str);
}

#pragma mark - install BundleId and Simulator
- (void)buildWillStart:(NSNotification *)notification
{
    NSLog(@"[CHPlugin] build will start.");
    self.currentDocuments = nil;
    self.currentBundleId = [self.class bundleIdInNotification:notification];
    self.currentDeviceAppPath = [self.class deviceAppPathInNotification:notification];
}

- (NSString *)currentDocuments
{
    if (_currentDocuments) {
        return _currentDocuments;
    }
    
    if (self.currentDeviceAppPath.length == 0 || self.currentBundleId.length == 0) {
        return nil;
    }
    
    NSArray *paths = [self.fileManager contentsOfDirectoryAtPath:self.currentDeviceAppPath error:nil];
    for (NSString *pathName in paths) {
        NSString *fileName = [self.currentDeviceAppPath stringByAppendingPathComponent:pathName];
        NSString *fileUrl = [fileName stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];
        
        if([self.fileManager fileExistsAtPath:fileUrl]){
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fileUrl];
            NSString *bundleId = [dict valueForKeyPath:@"MCMMetadataIdentifier"];
            if (bundleId.length != 0 && [self.currentBundleId isEqualToString:bundleId]) {
                _currentDocuments = [fileName stringByAppendingPathComponent:@"Documents"];
                return _currentDocuments;
            }
        }
    }
    
    return nil;
}


+ (NSString*)deviceAppPathInNotification:(NSNotification *)notification
{
    NSString *deviceId = [self.class deviceIdInNotification:notification];
    if (deviceId.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/%@/data/Containers/Data/Application", NSHomeDirectory(),deviceId];
    
}

+ (NSString*)deviceIdInNotification:(NSNotification *)notification
{
    id IDEBuildParameters = [notification.object valueForKey:@"_buildParameters"];
    if (![IDEBuildParameters isKindOfClass:NSClassFromString(@"IDEBuildParameters").class]) {
        NSLog(@"No _buildParameters in noti.object.");
        return nil;
    }
    
    id IDERunDestination = [IDEBuildParameters valueForKey:@"_activeRunDestination"];
    if (![IDERunDestination isKindOfClass:NSClassFromString(@"IDERunDestination").class]) {
        NSLog(@"No _activeRunDestination in IDEBuildParameters.");
        return nil;
    }
    
    id DVTiPhoneSimulator = [IDERunDestination valueForKey:@"_targetDevice"];
    if (![DVTiPhoneSimulator isKindOfClass:NSClassFromString(@"DVTiPhoneSimulator").class]) {
        NSLog(@"No _targetDevice in IDERunDestination.");
        return nil;
    }
    
    NSString *identifier = [DVTiPhoneSimulator valueForKey:@"_identifier"];
    if (![identifier isKindOfClass:NSString.class]) {
        NSLog(@"No _identifier in DVTiPhoneSimulator.");
        return nil;
    }

    return identifier;
}

+ (NSString*)bundleIdInNotification:(NSNotification *)notification
{
    NSString *infoPath = [self infoPathInNotification:notification];
    if (infoPath.length == 0) {
        return nil;
    }
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:infoPath];
    return dic[@"CFBundleIdentifier"];
}

+ (NSString*)infoPathInNotification:(NSNotification *)notification
{
    NSArray *buildables = [notification.object valueForKey:@"_buildables"];
    if (![buildables isKindOfClass:NSArray.class]) {
        NSLog(@"No _buildables in noti.object.");
        return nil;
    }
    
    id Xcode3TargetProduct = buildables[0];
    if (![Xcode3TargetProduct isKindOfClass:NSClassFromString(@"Xcode3TargetProduct").class]) {
        NSLog(@"No Xcode3TargetProduct in buildables.");
        return nil;
    }
    
    id Xcode3Target = [Xcode3TargetProduct valueForKey:@"_blueprint"];
    if (![Xcode3Target isKindOfClass:NSClassFromString(@"Xcode3Target").class]) {
        NSLog(@"No _blueprint in Xcode3TargetProduct.");
        return nil;
    }
    
    id PBXNativeTarget = [Xcode3Target valueForKey:@"_pbxTarget"];
    if (![PBXNativeTarget isKindOfClass:NSClassFromString(@"PBXNativeTarget").class]) {
        NSLog(@"No _pbxTarget in Xcode3Target.");
        return nil;
    }
    
    id PBXFileReference = [PBXNativeTarget valueForKey:@"_infoPlistRef"];
    if (![PBXFileReference isKindOfClass:NSClassFromString(@"PBXFileReference").class]) {
        NSLog(@"No _infoPlistRef in PBXNativeTarget.");
        return nil;
    }
    
    NSString *infoPath = [PBXFileReference valueForKey:@"_absolutePath"];
    if (![infoPath isKindOfClass:NSString.class]) {
        NSLog(@"No _absolutePath in PBXNativeTarget.");
        return nil;
    }
    
    return infoPath;
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
    NSLog(@"Notification: %@", [noti name]);   
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

- (NSFileManager *)fileManager
{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

@end
