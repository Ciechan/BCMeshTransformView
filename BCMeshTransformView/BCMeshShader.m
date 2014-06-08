//
//  BCMeshShader.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshShader.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@implementation BCMeshShader

- (BOOL)loadProgram
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    _program = glCreateProgram();
    
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:[self shaderName] ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader \"%@\"", [self shaderName]);
        return NO;
    }
    
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:[self shaderName] ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader \"%@\"", [self shaderName]);
        return NO;
    }
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    
    [self bindAttributeLocations];
    
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program %d for shader \"%@\"", _program, [self shaderName]);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    [self getUniformLocations];
    
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (void)dealloc
{
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader \"%@\"", [self shaderName]);
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader \"%@\" compile log:\n%s", [self shaderName], log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program \"%@\" link log:\n%s", [self shaderName], log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}



#pragma mark - Concrete

- (void)bindAttributeLocations
{
    glBindAttribLocation(self.program, BCVertexAttribPosition, "position");
    glBindAttribLocation(self.program, BCVertexAttribNormal, "normal");
    glBindAttribLocation(self.program, BCVertexAttribTexCoord, "texCoord");
}

- (void)getUniformLocations
{
    _viewProjectionMatrixUniform = glGetUniformLocation(self.program, "viewProjectionMatrix");
    _normalMatrixUniform = glGetUniformLocation(self.program, "normalMatrix");
    _lightDirectionUniform = glGetUniformLocation(self.program, "lightDirection");
    _diffuseFactorUniform = glGetUniformLocation(self.program, "diffuseFactor");
    _texSamplerUniform = glGetUniformLocation(self.program, "texSampler");
}

- (NSString *)shaderName
{
    return @"BCMeshShader";
}


@end
