//
//  BCMeshTexture.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshTexture.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation BCMeshTexture

- (void)setupOpenGL
{
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)dealloc
{
    if (_texture) {
        glDeleteTextures(1, &_texture);
    }
}



- (void)renderView:(UIView *)view
{
    const CGFloat Scale = [UIScreen mainScreen].scale;
    
    GLsizei width = view.layer.bounds.size.width * Scale;
    GLsizei height = view.layer.bounds.size.height * Scale;
    
    GLubyte *texturePixelBuffer = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(texturePixelBuffer,
                                                 width, height, 8, width * 4, colorSpace,
                                                 kCGImageAlphaPremultipliedLast |
                                                 kCGBitmapByteOrder32Big);
    CGContextScaleCTM(context, Scale, Scale);
    
    UIGraphicsPushContext(context);
    
    [view drawViewHierarchyInRect:view.layer.bounds afterScreenUpdates:NO];
    
    UIGraphicsPopContext();


    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    

    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texturePixelBuffer);
    glBindTexture(GL_TEXTURE_2D, 0);

    free(texturePixelBuffer);
}

@end
