//
//  BCMeshTransform+Interpolation.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshTransform+Interpolation.h"

@implementation BCMeshTransform (PrivateInterpolation)

static NSString *const BCMeshTransformViewErrorDomain = @"BCMeshTransformViewErrorDomain";
static NSString *const ErrorFormatString = @"Incompatible %@, animation will not be visible.";

static inline CGFloat lerp(CGFloat from, CGFloat to, double t)
{
    return to * t + from * (1.0 - t);
}

- (void)writeErrorToPointer:(NSError **)error withDescription:(NSString *)description
{
    if (!error) {
        return;
    }
    
    *error = [NSError errorWithDomain:BCMeshTransformViewErrorDomain
                                 code:0
                             userInfo:@{NSLocalizedDescriptionKey: description}];
}

- (BOOL)isCompatibleWithTransform:(BCMeshTransform *)otherTransform error:(NSError **)error
{
    if (otherTransform.faceCount != self.faceCount) {
        [self writeErrorToPointer:error withDescription:[NSString stringWithFormat:ErrorFormatString, @"face count"]];
        return NO;
    }
    
    if (otherTransform.vertexCount != self.vertexCount) {
        [self writeErrorToPointer:error withDescription:[NSString stringWithFormat:ErrorFormatString, @"vertex count"]];
        return NO;
    }
    
    if (![otherTransform.depthNormalization isEqualToString:self.depthNormalization]) {
        [self writeErrorToPointer:error withDescription:[NSString stringWithFormat:ErrorFormatString, @"depth normalization"]];
        return NO;
    }
    
    for (int i = 0; i < otherTransform.faceCount; i++) {
        BCMeshFace face = [self faceAtIndex:i];
        BCMeshFace otherFace = [otherTransform faceAtIndex:i];
        
        for (int j = 0; j < 4; j++) {
            if (face.indices[j] != otherFace.indices[j]) {
                [self writeErrorToPointer:error withDescription:[NSString stringWithFormat:ErrorFormatString, @"face vertex indexes"]];

                return NO;
            }
        }
    }
    
    return YES;
}

- (BCMeshTransform *)interpolateToTransform:(BCMeshTransform *)otherTransform withProgress:(double)progress
{
    NSAssert(otherTransform.vertexCount == self.vertexCount,
             @"Numbers of vertices in interpolated mesh transforms do not match");
    
    BCMutableMeshTransform *resultTransform = [self mutableCopy];
    
    for (int i = 0; i < self.vertexCount; i++) {
        BCMeshVertex vertex = [self vertexAtIndex:i];
        BCMeshVertex otherVertex = [otherTransform vertexAtIndex:i];
        BCMeshVertex outputVertex;
        
        outputVertex.from.x = lerp(vertex.from.x, otherVertex.from.x, progress);
        outputVertex.from.y = lerp(vertex.from.y, otherVertex.from.y, progress);
        
        outputVertex.to.x = lerp(vertex.to.x, otherVertex.to.x, progress);
        outputVertex.to.y = lerp(vertex.to.y, otherVertex.to.y, progress);
        outputVertex.to.z = lerp(vertex.to.z, otherVertex.to.z, progress);
        
        [resultTransform replaceVertexAtIndex:i withVertex:outputVertex];
    }
    
    return resultTransform;
}

@end
