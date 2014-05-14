//
//  BCJellyDemoViewController.m
//  BCMeshTransformViewDemo
//
//  Created by Bartosz Ciechanowski on 13/05/14.
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCJellyDemoViewController.h"
#import "BCMeshTransformView.h"
#import "BCMeshTransform+DemoTransforms.h"


@interface BCJellyDemoViewController ()

@end

@implementation BCJellyDemoViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.layer.cornerRadius = 125.0;
    label.layer.masksToBounds = YES;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor colorWithRed:0.11 green:0.72 blue:0.6 alpha:1];
    label.text = @"tap";
    label.font = [UIFont systemFontOfSize:140.0];
    
    
    [self.transformView.contentView addSubview:label];
    self.transformView.bounds = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width);
    self.transformView.autoresizingMask = UIViewAutoresizingNone;
    self.transformView.meshTransform = [BCMeshTransform shiverTransformWithPhase:0.0 magnitude:0.0];

    label.center = CGPointMake(CGRectGetMidX(self.transformView.bounds),
                               CGRectGetMidY(self.transformView.bounds));
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void)tap:(UITapGestureRecognizer *)sender
{
    [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transformView.meshTransform = [BCMeshTransform shiverTransformWithPhase:drand48() * M_PI * 2 magnitude:0.035];
    } completion:^(BOOL finished) {
        if (finished) {
            [self animate];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self animate];
}

- (void)animate
{
    const CGFloat Magnitude = 0.04;
    
    // poor man's keyframes, so sad...
    
    [UIView animateWithDuration:2.0 animations:^{
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.transformView.meshTransform = [BCMeshTransform shiverTransformWithPhase:M_PI_2/2 magnitude:Magnitude];
    } completion:^(BOOL finished) {
        if (!finished) { return; }
        [UIView animateWithDuration:2.0 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveLinear];
            self.transformView.meshTransform = [BCMeshTransform shiverTransformWithPhase:M_PI_2 magnitude:Magnitude];
        } completion:^(BOOL finished) {
                    if (!finished) { return; }
            [UIView animateWithDuration:2.0 animations:^{
                [UIView setAnimationCurve:UIViewAnimationCurveLinear];
                self.transformView.meshTransform = [BCMeshTransform shiverTransformWithPhase:3*M_PI_2/2 magnitude:Magnitude];
            } completion:^(BOOL finished) {
                if (!finished) { return; }
                [UIView animateWithDuration:2.0 animations:^{
                    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
                    self.transformView.meshTransform = [BCMeshTransform shiverTransformWithPhase:M_PI magnitude:Magnitude];
                } completion:^(BOOL finished) {
                    if (!finished) { return; }
                    [self animate];
                }];
            }];
        }];
    }];
}


@end
