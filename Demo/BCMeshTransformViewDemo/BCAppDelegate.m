//
//  BCAppDelegate.m
//  BCMeshTransformViewDemo
//
//  Created by Bartosz Ciechanowski on 11/05/14.
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCAppDelegate.h"

#import "BCDemoTableViewController.h"


@implementation BCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BCDemoTableViewController *tableViewController = [BCDemoTableViewController new];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tableViewController];
    

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = navController;

    [self.window makeKeyAndVisible];
    
    self.window.tintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    
    return YES;
}


@end
