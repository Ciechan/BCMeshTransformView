//
//  BCMeshBuffer.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshBuffer.h"
#import "BCMeshShader.h"
#import "BCMeshTransform.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

typedef struct BCVertex {
    GLKVector3 position;
    GLKVector3 normal;
    GLKVector2 uv;
} BCVertex;

@implementation BCMeshBuffer
{
    GLuint _indexBuffer;
    GLuint _vertexBuffer;
    
    GLsizeiptr _indexBufferCapacity;
    GLsizeiptr _vertexBufferCapacity;
}

- (void)setupOpenGL
{
    glGenVertexArraysOES(1, &_VAO);
    glGenBuffers(1, &_indexBuffer);
    glGenBuffers(1, &_vertexBuffer);
}

- (void)dealloc
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_VAO);
}



- (void)rebindVAO
{
    glBindVertexArrayOES(_VAO);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    
    glEnableVertexAttribArray(BCVertexAttribPosition);
    glVertexAttribPointer(BCVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(BCVertex), (void *)offsetof(BCVertex, position));
    
    glEnableVertexAttribArray(BCVertexAttribNormal);
    glVertexAttribPointer(BCVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(BCVertex), (void *)offsetof(BCVertex, normal));
    
    glEnableVertexAttribArray(BCVertexAttribTexCoord);
    glVertexAttribPointer(BCVertexAttribTexCoord, 2, GL_FLOAT, GL_FALSE, sizeof(BCVertex), (void *)offsetof(BCVertex, uv));
    
    glBindVertexArrayOES(0);
}




#pragma mark - Buffers Filling


- (void)fillWithMeshTransform:(BCMeshTransform *)transform
                positionScale:(GLKVector3)positionScale
{
    const int IndexesPerFace = 6;
    
    NSUInteger faceCount = transform.faceCount;
    NSUInteger vertexCount = transform.vertexCount;
    NSUInteger indexCount = faceCount * IndexesPerFace;
    
    [self resizeBuffersToVertexCount:vertexCount indexCount:indexCount];

    [self fillBuffersWithBlock:^(BCVertex *vertexData, GLuint *indexData) {
        for (int i = 0; i < vertexCount; i++) {
            BCMeshVertex meshVertex = [transform vertexAtIndex:i];
            CGPoint uv = meshVertex.from;

            BCVertex vertex;
            vertex.position = GLKVector3Make(meshVertex.to.x, meshVertex.to.y, meshVertex.to.z);
            vertex.uv = GLKVector2Make(uv.x, 1.0 - uv.y);
            vertex.normal = GLKVector3Make(0.0f, 0.0f, 0.0f);
            vertexData[i] = vertex;
        }
        
        for (int i = 0; i < faceCount; i++) {
            BCMeshFace face = [transform faceAtIndex:i];
            GLKVector3 weightedFaceNormal = GLKVector3Make(0.0f, 0.0f, 0.0f);
            
            // CAMeshTransform seems to be using the following order
            const int Winding[2][3] = {
                {0, 1, 2},
                {2, 3, 0}
            };
            
            GLKVector3 vertices[4];
            
            for (int j = 0; j < 4; j++) {
                unsigned int faceIndex = face.indices[j];
                if (faceIndex >= vertexCount) {
                    NSLog(@"Vertex index %u in face %d is out of bounds!", faceIndex, i);
                    return;
                }
                vertices[j] = GLKVector3Multiply(vertexData[faceIndex].position, positionScale);
            }
            
            for (int triangle = 0; triangle < 2; triangle++) {
                
                int aIndex = face.indices[Winding[triangle][0]];
                int bIndex = face.indices[Winding[triangle][1]];
                int cIndex = face.indices[Winding[triangle][2]];
                
                indexData[IndexesPerFace * i + triangle * 3 + 0] = aIndex;
                indexData[IndexesPerFace * i + triangle * 3 + 1] = bIndex;
                indexData[IndexesPerFace * i + triangle * 3 + 2] = cIndex;
                
                GLKVector3 a = vertices[Winding[triangle][0]];
                GLKVector3 b = vertices[Winding[triangle][1]];
                GLKVector3 c = vertices[Winding[triangle][2]];
                
                GLKVector3 ab = GLKVector3Subtract(a, b);
                GLKVector3 cb = GLKVector3Subtract(c, b);
                
                GLKVector3 weightedNormal = GLKVector3CrossProduct(ab, cb);

                weightedFaceNormal = GLKVector3Add(weightedFaceNormal, weightedNormal);
            }
            
            // accumulate weighted normal over all faces
            
            for (int i = 0; i < 4; i++) {
                int vertexIndex = face.indices[i];
                vertexData[vertexIndex].normal = GLKVector3Add(vertexData[vertexIndex].normal, weightedFaceNormal);
            }
        }
        
        for (int i = 0; i < vertexCount; i++) {
            
            GLKVector3 normal = vertexData[i].normal;
            float length = GLKVector3Length(normal);
            
            if (length > 0.0) {
                vertexData[i].normal = GLKVector3MultiplyScalar(normal, 1.0/length);
            }
        }
    }];
    
    
    _indiciesCount = (GLsizei)indexCount;
}

- (void)fillBuffersWithBlock:(void (^)(BCVertex *vertexData, GLuint *indexData))block
{
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    BCVertex *vertexData = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    GLuint *indexData = glMapBufferOES(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    
    block(vertexData, indexData);
    
    glUnmapBufferOES(GL_ELEMENT_ARRAY_BUFFER);
    glUnmapBufferOES(GL_ARRAY_BUFFER);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
}

#pragma mark - Resizing

static inline GLsizeiptr nextPoTForSize(NSUInteger size)
{
    // using a builtin to Count Leading Zeros
    unsigned int bitCount = sizeof(unsigned int) * CHAR_BIT;
    unsigned int log2 = bitCount - __builtin_clz((unsigned int)size);
    GLsizeiptr nextPoT = 1u << log2;
    
    return nextPoT;
}

- (void)resizeBuffersToVertexCount:(NSUInteger)vertexCount indexCount:(NSUInteger)indexCount
{
    BOOL rebindVAO = NO;
    
    if (_vertexBufferCapacity < vertexCount) {
        _vertexBufferCapacity = nextPoTForSize(vertexCount);
        [self resizeVertexBufferToCapacity:_vertexBufferCapacity];
        rebindVAO = YES;
    }
    
    if (_indexBufferCapacity < indexCount) {
        _indexBufferCapacity = nextPoTForSize(indexCount);
        [self resizeIndexBufferToCapacity:_indexBufferCapacity];
        rebindVAO = YES;
    }
    
    if (rebindVAO) {
        [self rebindVAO];
    }
}


- (void)resizeVertexBufferToCapacity:(GLsizeiptr)capacity
{
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, capacity * sizeof(BCVertex), NULL, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

- (void)resizeIndexBufferToCapacity:(GLsizeiptr)capacity
{
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, capacity * sizeof(GLuint), NULL, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

@end
