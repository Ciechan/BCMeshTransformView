//
//  BCDemoViewController.m
//  BCMeshTransformViewDemo
//
//  Created by Bartosz Ciechanowski on 11/05/14.
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCDemoViewController.h"
#import "BCMeshTransformView.h"

@interface BCDemoViewController ()

@end

@implementation BCDemoViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _transformView = [[BCMeshTransformView alloc] initWithFrame:self.view.bounds];
    _transformView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:_transformView];
}



@end
