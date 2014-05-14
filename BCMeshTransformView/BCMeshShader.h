//
//  BCMeshShader.h
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BCVertexAttrib) {
    BCVertexAttribPosition,
    BCVertexAttribNormal,
    BCVertexAttribTexCoord
};

@interface BCMeshShader : NSObject

@property (nonatomic, readonly) GLuint program;
@property (nonatomic, readonly) GLint viewProjectionMatrixUniform;
@property (nonatomic, readonly) GLint normalMatrixUniform;
@property (nonatomic, readonly) GLint lightDirectionUniform;
@property (nonatomic, readonly) GLint diffuseFactorUniform;

@property (nonatomic, readonly) GLint texSamplerUniform;

- (BOOL)loadProgram;

@end

