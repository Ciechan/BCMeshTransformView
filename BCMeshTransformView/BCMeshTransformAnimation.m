//
//  BCMeshTransformAnimation.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshTransformAnimation.h"
#import "BCMeshTransform.h"
#import "BCMeshTransform+Interpolation.h"

typedef double (^ProgressBlock)(double progress);

@interface BCMeshTransformAnimation()

@property (nonatomic) NSTimeInterval time;
@property (nonatomic) NSTimeInterval duration;

@property (nonatomic) float repeatCount;
@property (nonatomic) BOOL autoreverses;

@property (nonatomic, copy) BCMeshTransform *startTransform;
@property (nonatomic, copy) BCMeshTransform *endTransform;

@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic) BOOL areTransformsCompatible;

@end


@implementation BCMeshTransformAnimation


- (instancetype)initWithAnimation:(CAAnimation *)animation
                 currentTransform:(BCMeshTransform *)currentTransform
             destinationTransform:(BCMeshTransform *)destinationTransform
{
    self = [super init];
    if (self) {
        self.time = -animation.beginTime;
        self.duration = animation.duration;
        self.progressBlock = progressBlockForTimingFunction(animation.timingFunction);
        self.repeatCount = animation.repeatCount ?: 1.0f;
        self.autoreverses = animation.autoreverses;
        
        self.startTransform = currentTransform;
        self.endTransform = destinationTransform;
        
        NSError *error;
        self.areTransformsCompatible = [currentTransform isCompatibleWithTransform:destinationTransform error:&error];
        
        if (!self.areTransformsCompatible) {
            NSLog(@"%@", error.localizedDescription);
        }
    }
    return self;
}


- (BCMeshTransform *)currentMeshTransform
{
    if (!self.areTransformsCompatible) {
        return self.endTransform;
    }
    
    double t = (MIN(MAX(0.0, self.time), [self totalTime])) / self.duration;
    double fract = fmod(t, 1.0);
    double normalized = fract;
    
    BOOL hasReachedPeakT = fract == 0.0 && t > 0.0 && !self.autoreverses;
    BOOL returnsToInitialState = self.autoreverses && (NSInteger)t % 2 == 1;
    
    if (hasReachedPeakT || returnsToInitialState) {
        normalized = 1.0 - fract;
    }

    double p = self.progressBlock(normalized);
    
    return [self.startTransform interpolateToTransform:self.endTransform withProgress:p];
}

- (void)tick:(NSTimeInterval)dt
{
    self.time += dt;
}

- (NSTimeInterval)totalTime
{
    return self.duration * self.repeatCount * (self.autoreverses ? 2.0 : 1.0);
}

- (BOOL)isCompleted
{
    return self.time >= [self totalTime];
}

#pragma mark - Animation Curves

double newtonRaphsonCurveIntersection(CGPoint p1, CGPoint p2, CGFloat x)
{
    const int Iterations = 7;
 
    double t = x;
    
    for (int i = 0; i < Iterations; i++) {
        double nt = 1.0 - t;
        
        double f = 3.0*nt*nt*t*p1.x + 3.0*nt*t*t*p2.x + t*t*t - x;
        double df = -3.0*(p1.x*(-3.0*t*t + 4.0*t - 1.0) + t*(3.0*p2.x*t - 2.0*p2.x - t));
        
        t -= f/df;
    }
    
    double nt = 1.0 - t;
    
    return 3.0*nt*nt*t*p1.y + 3.0*nt*t*t*p2.y + t*t*t;
}



ProgressBlock progressBlockForTimingFunction(CAMediaTimingFunction *timingFunction)
{
    float points[2][2] ;
    
    for (int i = 0; i < 2; i++) {
        [timingFunction getControlPointAtIndex:i + 1 values:points[i]];
    }
    
    CGPoint p1 = CGPointMake(points[0][0], points[0][1]);
    CGPoint p2 = CGPointMake(points[1][0], points[1][1]);
    
    return ^(double t) {
        return (t == 0.0 || t == 1.0) ? t : newtonRaphsonCurveIntersection(p1, p2, t);
    };
}

@end
