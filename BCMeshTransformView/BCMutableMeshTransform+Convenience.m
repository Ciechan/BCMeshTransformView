//
//  BCMutableMeshTransform+Convenience.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMutableMeshTransform+Convenience.h"

@implementation BCMutableMeshTransform (Convenience)



+ (instancetype)identityMeshTransformWithNumberOfRows:(NSUInteger)rowsOfFaces
                                      numberOfColumns:(NSUInteger)columnsOfFaces
{
    NSParameterAssert(rowsOfFaces >= 1);
    NSParameterAssert(columnsOfFaces >= 1);
    
    BCMutableMeshTransform *transform = [BCMutableMeshTransform new];
    

    for (int row = 0; row <= rowsOfFaces; row++) {
        
        for (int col = 0; col <= columnsOfFaces; col++) {
            
            CGFloat x = (CGFloat)col/(columnsOfFaces);
            CGFloat y = (CGFloat)row/(rowsOfFaces);
            
            BCMeshVertex vertex = {
                .from = {x, y},
                .to = {x, y, 0.0f}
            };
            
            [transform addVertex:vertex];
        }
    }
    
    for (int row = 0; row < rowsOfFaces; row++) {
        for (int col = 0; col < columnsOfFaces; col++) {
            BCMeshFace face = {
                .indices = {
                    (unsigned int)((row + 0) * (columnsOfFaces + 1) + col),
                    (unsigned int)((row + 0) * (columnsOfFaces + 1) + col + 1),
                    (unsigned int)((row + 1) * (columnsOfFaces + 1) + col + 1),
                    (unsigned int)((row + 1) * (columnsOfFaces + 1) + col)
                }
            };
            
            [transform addFace:face];
        }
    }
    
    transform.depthNormalization = kBCDepthNormalizationAverage;
    return transform;
}


+ (instancetype)meshTransformWithVertexCount:(NSUInteger)vertexCount
                             vertexGenerator:(BCMeshVertex (^)(NSUInteger vertexIndex))vertexGenerator
                                   faceCount:(NSUInteger)faceCount
                                       faceGenerator:(BCMeshFace (^)(NSUInteger faceIndex))faceGenerator
{
    BCMutableMeshTransform *transform = [BCMutableMeshTransform new];
    
    for (int i = 0; i < vertexCount; i++) {
        [transform addVertex:vertexGenerator(i)];
    }
    
    for (int i = 0; i < faceCount; i++) {
        [transform addFace:faceGenerator(i)];
    }
    
    return transform;
}




- (void)mapVerticesUsingBlock:(BCMeshVertex (^)(BCMeshVertex vertex, NSUInteger vertexIndex))block
{
    NSUInteger count = self.vertexCount;
    for (int i = 0; i < count; i++) {
        [self replaceVertexAtIndex:i withVertex:block([self vertexAtIndex:i], i)];
    }
}

@end
