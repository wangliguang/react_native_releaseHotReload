/**
 * Copyright (c) 2015-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import "RCTBridge.h"
#import <React/RCTBridge+Private.h>

@interface AppDelegate ()
{
  RCTBridge *bridge;
  UINavigationController *rootViewController;
  UIViewController *mainViewController;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // 加载基础bundle
  NSURL *jsCodeLocation = [[NSBundle mainBundle] URLForResource:@"base.ios" withExtension:@"bundle"];
  bridge = [[RCTBridge alloc] initWithBundleURL:jsCodeLocation
                                 moduleProvider:nil
                                  launchOptions:launchOptions];
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  mainViewController = [UIViewController new];
  mainViewController.view = [[NSBundle mainBundle] loadNibNamed:@"MainScreen" owner:self options:nil].lastObject;
  rootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
  mainViewController.edgesForExtendedLayout = UIRectEdgeNone;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  UIButton* buz1 = [mainViewController.view viewWithTag:101];
  UIButton* buz2 = [mainViewController.view viewWithTag:91];
  [buz1 addTarget:self action:@selector(goBuz1:) forControlEvents:UIControlEventTouchUpInside];
  [buz2 addTarget:self action:@selector(goBuz2:) forControlEvents:UIControlEventTouchUpInside];
  return YES;
}

-(void)goBuz1:(UIButton *)button{
  [self gotoBuzWithModuleName:@"react_native_releaseHotReload" bundleName:@"index.ios"];
}

-(void)goBuz2:(UIButton *)button{
  [self gotoBuzWithModuleName:@"react_native_releaseHotReload" bundleName:@"indexUpdate.ios"];
}


-(void) gotoBuzWithModuleName:(NSString*)moduleName bundleName:(NSString*)bundleName{
  
  NSURL *jsCodeLocationBuz = [[NSBundle mainBundle] URLForResource:bundleName withExtension:@"bundle"];
  NSError *error = nil;
  NSData *sourceBuz = [NSData dataWithContentsOfFile:jsCodeLocationBuz.path
                                             options:NSDataReadingMappedIfSafe
                                               error:&error];
  [bridge.batchedBridge executeSourceCode:sourceBuz sync:NO];
  
  RCTRootView* view = [[RCTRootView alloc] initWithBridge:bridge moduleName:moduleName initialProperties:nil];
  UIViewController* controller = [UIViewController new];
  [controller setView:view];
  [mainViewController.navigationController pushViewController:controller animated:YES];
}


@end

