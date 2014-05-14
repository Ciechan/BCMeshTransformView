//
//  BCMeshTransform+Interpolation.h
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshTransform.h"

@interface BCMeshTransform (PrivateInterpolation)

- (BOOL)isCompatibleWithTransform:(BCMeshTransform *)otherTransform error:(NSError **)error;
- (BCMeshTransform *)interpolateToTransform:(BCMeshTransform *)otherTransform withProgress:(double)progress;

@end
