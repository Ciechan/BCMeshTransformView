//
//  BCMeshTransform.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshTransform.h"

#import <vector>

NSString * const kBCDepthNormalizationNone = @"none";
NSString * const kBCDepthNormalizationWidth = @"width";
NSString * const kBCDepthNormalizationHeight = @"height";
NSString * const kBCDepthNormalizationMin = @"min";
NSString * const kBCDepthNormalizationMax = @"max";
NSString * const kBCDepthNormalizationAverage = @"average";


@interface BCMeshTransform()
{
    @protected
    // Performance really matters here, CAMeshTransform makes use of vectors as well
    std::vector<BCMeshFace> _faces;
    std::vector<BCMeshVertex> _vertices;
}

@property (nonatomic, copy, readwrite) NSString *depthNormalization;

@end


@implementation BCMeshTransform

+ (instancetype)meshTransformWithVertexCount:(NSUInteger)vertexCount
                                    vertices:(BCMeshVertex *)vertices
                                   faceCount:(NSUInteger)faceCount
                                       faces:(BCMeshFace *)faces
                          depthNormalization:(NSString *)depthNormalization
{
    return [[self alloc] initWithVertexCount:vertexCount
                                    vertices:vertices
                                   faceCount:faceCount
                                       faces:faces
                          depthNormalization:depthNormalization];
}

- (instancetype)init
{
    return [self initWithVertexCount:0
                            vertices:NULL
                           faceCount:0
                               faces:NULL
                  depthNormalization:kBCDepthNormalizationNone];
}

- (instancetype)initWithVertexCount:(NSUInteger)vertexCount
                           vertices:(BCMeshVertex *)vertices
                          faceCount:(NSUInteger)faceCount
                              faces:(BCMeshFace *)faces
                 depthNormalization:(NSString *)depthNormalization
{
    self = [super init];
    if (self) {
        
        _vertices = std::vector<BCMeshVertex>();
        _vertices.reserve(vertexCount);
        
        _faces = std::vector<BCMeshFace>();
        _faces.reserve(faceCount);
        
        for (int i = 0; i < vertexCount; i++) {
            _vertices.push_back(vertices[i]);
        }

        for (int i = 0; i < faceCount; i++) {
            _faces.push_back(faces[i]);
        }
        
        self.depthNormalization = depthNormalization;
    }
    return self;
}

- (id)copyWithClass:(Class)cls
{
    BCMeshTransform *copy = [cls new];
    copy->_depthNormalization = _depthNormalization;
    copy->_vertices = std::vector<BCMeshVertex>(_vertices);
    copy->_faces = std::vector<BCMeshFace>(_faces);
    
    return copy;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self copyWithClass:[BCMeshTransform class]];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [self copyWithClass:[BCMutableMeshTransform class]];
}


- (NSUInteger)faceCount
{
    return _faces.size();
}

- (NSUInteger)vertexCount
{
    return _vertices.size();
}

- (BCMeshFace)faceAtIndex:(NSUInteger)faceIndex
{
    NSAssert(faceIndex < _faces.size(), @"Requested faceIndex (%lu) is larger or equal to number of faces (%lu)", (unsigned long)faceIndex, _faces.size());
    
    return _faces[faceIndex];
}

- (BCMeshVertex)vertexAtIndex:(NSUInteger)vertexIndex
{
    NSAssert(vertexIndex < _vertices.size(), @"Requested vertexIndex (%lu) is larger or equal to number of vertices (%lu)", (unsigned long)vertexIndex, _vertices.size());
    
    return _vertices[vertexIndex];
}

@end


@implementation BCMutableMeshTransform

+ (instancetype)meshTransform
{
    return [[self alloc] init];
}

- (void)addFace:(BCMeshFace)face
{
    _faces.push_back(face);
}

- (void)removeFaceAtIndex:(NSUInteger)faceIndex
{
    _faces.erase(_faces.begin() + faceIndex);
}

- (void)replaceFaceAtIndex:(NSUInteger)faceIndex withFace:(BCMeshFace)face
{
    _faces[faceIndex] = face;
}


- (void)addVertex:(BCMeshVertex)vertex
{
    _vertices.push_back(vertex);
}

- (void)removeVertexAtIndex:(NSUInteger)vertexIndex
{
    _vertices.erase(_vertices.begin() + vertexIndex);
}

- (void)replaceVertexAtIndex:(NSUInteger)vertexIndex withVertex:(BCMeshVertex)vertex
{
    _vertices[vertexIndex] = vertex;
}


@end



