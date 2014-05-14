//
//  BCCurtainDemoViewController.m
//  BCMeshTransformViewDemo
//
//  Created by Bartosz Ciechanowski on 11/05/14.
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCCurtainDemoViewController.h"
#import "BCMeshTransformView.h"
#import "BCMeshTransform+DemoTransforms.h"


@interface BCCurtainDemoViewController () <UIGestureRecognizerDelegate>
@property (nonatomic) BOOL drags;
@property (nonatomic) CGFloat surplus;
@end

@implementation BCCurtainDemoViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UILabel *secretLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    secretLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    secretLabel.textAlignment = NSTextAlignmentCenter;
    secretLabel.text = @"release finger";
    
    [self.view insertSubview:secretLabel atIndex:0];
    
    
    UIView *container = [[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.transformView.bounds, UIEdgeInsetsMake(0, 0, 50, 0))];
    container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    container.backgroundColor = [UIColor colorWithRed:0.85 green:0.25 blue:0.27 alpha:1];
    
    UILabel *label = [[UILabel alloc] initWithFrame:container.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.textColor = [UIColor whiteColor];
    label.text = @"Reveal\nthe\nSecret";
    label.font = [UIFont systemFontOfSize:30.0];
    [container addSubview:label];
    
    UILabel *arrowLabel = [[UILabel alloc] initWithFrame:container.bounds];
    arrowLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    arrowLabel.textAlignment = NSTextAlignmentRight;
    arrowLabel.textColor = [UIColor whiteColor];
    arrowLabel.font = [UIFont systemFontOfSize:16.0];
    arrowLabel.text = @"←";
    [container addSubview:arrowLabel];
    
    
    [self.transformView.contentView addSubview:container];
    
    self.transformView.diffuseLightFactor = 0.5;
    
    CATransform3D perspective = CATransform3DIdentity;
    perspective.m34 = -1.0/2000.0;
    
    self.transformView.supplementaryTransform = perspective;
    [self setIdleTransform];
    
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    panRecognizer.delegate = self;
    panRecognizer.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self.transformView];
    
    return point.x > self.view.bounds.size.width - 30.0;
}

- (void)pan:(UIPanGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self.transformView];
    
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.surplus = self.view.bounds.size.width - point.x;
            
            // FALL THROUGH
        case UIGestureRecognizerStateChanged:
            self.transformView.meshTransform = [BCMutableMeshTransform curtainMeshTransformAtPoint:CGPointMake(point.x + self.surplus, point.y)
                                                                                        boundsSize:self.transformView.bounds.size];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat percent = 1.0 - point.x/self.transformView.bounds.size.width;
            
            NSTimeInterval duration = 0.1 + 0.5 * percent;
            [UIView animateWithDuration:duration animations:^{
                [self setIdleTransform];
            }];
            break;
        }
            
        default:
            break;
    }
}

- (void)setIdleTransform
{
    self.transformView.meshTransform = [BCMutableMeshTransform curtainMeshTransformAtPoint:CGPointMake(self.view.bounds.size.width, self.view.bounds.size.height/2.0)
                                             boundsSize:self.transformView.bounds.size];
}


@end
