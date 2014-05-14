//
//  BCMutableMeshTransform+Convenience.h
//  BCMeshTransformView
//
//  Created by Bartosz Ciechanowski on 24/04/14.
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshTransform.h"

@interface BCMutableMeshTransform (Convenience)

// Creates rectangular mesh transform with facesRows by facesColumns faces and equally spread vertices.
// Created transform is an identity transform – it doesn't introduce any distrubances.
// Number of rows and columns must be larger or equal to 1.
+ (instancetype)identityMeshTransformWithNumberOfRows:(NSUInteger)rowsOfFaces
                                      numberOfColumns:(NSUInteger)columnsOfFaces;


+ (instancetype)meshTransformWithVertexCount:(NSUInteger)vertexCount
                             vertexGenerator:(BCMeshVertex (^)(NSUInteger vertexIndex))vertexGenerator
                                   faceCount:(NSUInteger)faceCount
                               faceGenerator:(BCMeshFace (^)(NSUInteger faceIndex))faceGenerator;

// Enumerates over vertices and maps them to some other vertices
- (void)mapVerticesUsingBlock:(BCMeshVertex (^)(BCMeshVertex vertex, NSUInteger vertexIndex))block;

@end
