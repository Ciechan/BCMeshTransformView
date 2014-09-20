//
//  BCMeshTransformView.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "BCMeshTransformView.h"
#import "BCMeshContentView.h"

#import "BCMeshShader.h"
#import "BCMeshBuffer.h"
#import "BCMeshTexture.h"

#import "BCMeshTransformAnimation.h"

#import "BCMutableMeshTransform+Convenience.h"

@interface BCMeshTransformView() <GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;

@property (nonatomic, strong) BCMeshShader *shader;
@property (nonatomic, strong) BCMeshBuffer *buffer;
@property (nonatomic, strong) BCMeshTexture *texture;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) BCMeshTransformAnimation *animation;

@property (nonatomic, copy) BCMeshTransform *presentationMeshTransform;

@property (nonatomic, strong) UIView *dummyAnimationView;

@property (nonatomic) BOOL pendingContentRendering;

@end


@implementation BCMeshTransformView

+ (EAGLContext *)renderingContext
{
    static EAGLContext *context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    });
    
    return context;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}


- (void)commonInit
{
    self.opaque = NO;
    
    _glkView = [[GLKView alloc] initWithFrame:self.bounds context:[BCMeshTransformView renderingContext]];
    _glkView.delegate = self;
    _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    _glkView.opaque = NO;
    
    [super addSubview:_glkView];
    
    _diffuseLightFactor = 1.0f;
    _lightDirection = BCPoint3DMake(0.0, 0.0, 1.0);
    
    _supplementaryTransform = CATransform3DIdentity;
    
    UIView *contentViewWrapperView = [UIView new];
    contentViewWrapperView.clipsToBounds = YES;
    [super addSubview:contentViewWrapperView];
    
    __weak typeof(self) welf = self; // thank you John Siracusa!
    _contentView = [[BCMeshContentView alloc] initWithFrame:self.bounds
                                                changeBlock:^{
                                                    [welf setNeedsContentRendering];
                                                } tickBlock:^(CADisplayLink *displayLink) {
                                                    [welf displayLinkTick:displayLink];
                                                }];
    
    [contentViewWrapperView addSubview:_contentView];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:_contentView selector:@selector(displayLinkTick:)];
    _displayLink.paused = YES;
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // a dummy view that's used for fetching the parameters
    // of a current animation block and getting animated
    self.dummyAnimationView = [UIView new];
    [contentViewWrapperView addSubview:self.dummyAnimationView];
    
    _shader = [BCMeshShader new];
    _buffer = [BCMeshBuffer new];
    _texture = [BCMeshTexture new];
    
    [self setupGL];
    
    self.meshTransform = [BCMutableMeshTransform identityMeshTransformWithNumberOfRows:1 numberOfColumns:1];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.glkView.frame = self.bounds;
    self.contentView.bounds = self.bounds;
}

#pragma mark - Setters

- (void)setMeshTransform:(BCMeshTransform *)meshTransform
{
    // If we're inside an animation block, then we change properties of
    // a dummy animation layer so that it gets the same animation context.
    // We're changing the values twice, since no animation will be added
    // if the from and to values are equal. This also ensures that the completion
    // block of the calling animation gets executed when animation is finished.
    
    [self.dummyAnimationView.layer removeAllAnimations];
    self.dummyAnimationView.layer.opacity = 1.0;
    self.dummyAnimationView.layer.opacity = 0.0;
    CAAnimation *animation = [self.dummyAnimationView.layer animationForKey:@"opacity"];
    
    if ([animation isKindOfClass:[CABasicAnimation class]]) {
        [self setAnimation:[[BCMeshTransformAnimation alloc] initWithAnimation:animation
                                                              currentTransform:self.presentationMeshTransform
                                                          destinationTransform:meshTransform]];
    } else {
        self.animation = nil;
        [self setPresentationMeshTransform:meshTransform];
    }
    
    _meshTransform = [meshTransform copy];
}

- (void)setPresentationMeshTransform:(BCMeshTransform *)presentationMeshTransform
{
    _presentationMeshTransform = [presentationMeshTransform copy];
    
    [self.buffer fillWithMeshTransform:presentationMeshTransform
                         positionScale:[self positionScaleWithDepthNormalization:self.presentationMeshTransform.depthNormalization]];
    [self.glkView setNeedsDisplay];
}

- (void)setLightDirection:(BCPoint3D)lightDirection
{
    _lightDirection = lightDirection;
    [self.glkView setNeedsDisplay];
}

- (void)setDiffuseLightFactor:(float)diffuseLightFactor
{
    _diffuseLightFactor = diffuseLightFactor;
    [self.glkView setNeedsDisplay];
}

- (void)setSupplementaryTransform:(CATransform3D)supplementaryTransform
{
    _supplementaryTransform = supplementaryTransform;
    [self.glkView setNeedsDisplay];
}

- (void)setAnimation:(BCMeshTransformAnimation *)animation
{
    if (animation) {
        self.displayLink.paused = NO;
    }
    _animation = animation;
}

- (void)setNeedsContentRendering
{
    if (self.pendingContentRendering == NO) {
        // next run loop tick
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0)), dispatch_get_main_queue(), ^{
            [self.texture renderView:self.contentView];
            [self.glkView setNeedsDisplay];
            
            self.pendingContentRendering = NO;
        });
        
        self.pendingContentRendering = YES;
    }
}

#pragma mark - Hit Testing

// We're cheating on the view hierarchy, telling it that contentView is not clipped by wrapper view
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    return [self.contentView hitTest:point withEvent:event];
}


#pragma mark - Animation Handling

- (void)displayLinkTick:(CADisplayLink *)displayLink
{
    [self.animation tick:displayLink.duration];
    
    if (self.animation) {
        self.presentationMeshTransform = self.animation.currentMeshTransform;
        
        if (self.animation.isCompleted) {
            self.animation = nil;
            self.displayLink.paused = YES;
        }
    } else {
        self.displayLink.paused = YES;
    }
}


#pragma mark - OpenGL Handling

- (void)setupGL
{
    [EAGLContext setCurrentContext:[BCMeshTransformView renderingContext]];
    
    [self.shader loadProgram];
    [self.buffer setupOpenGL];
    [self.texture setupOpenGL];
    
    // force initial texture rendering
    [self.texture renderView:self.contentView];
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glEnable(GL_DEPTH_TEST);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    GLKMatrix4 viewProjectionMatrix = [self transformMatrix];
    GLKMatrix3 normalMatrix = GLKMatrix4GetMatrix3(viewProjectionMatrix);
    
    bool invertible;
    normalMatrix = GLKMatrix3InvertAndTranspose(normalMatrix, &invertible);
    
    // Letting the final transform flatten the vertices so that they
    // won't get clipped by near/far planes that easily
    const float ZFlattenScale = 0.0005;
    viewProjectionMatrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(1.0, 1.0, ZFlattenScale), viewProjectionMatrix);
    
    GLKVector3 lightDirection = GLKVector3Normalize(GLKVector3Make(_lightDirection.x, _lightDirection.y, _lightDirection.z));
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(self.buffer.VAO);
    
    glUseProgram(self.shader.program);
    glUniform1i(self.shader.texSamplerUniform, 0);
    glUniform3fv(self.shader.lightDirectionUniform, 1, lightDirection.v);
    glUniform1f(self.shader.diffuseFactorUniform, _diffuseLightFactor);
    glUniformMatrix4fv(self.shader.viewProjectionMatrixUniform, 1, 0, viewProjectionMatrix.m);
    glUniformMatrix3fv(self.shader.normalMatrixUniform, 1, 0, normalMatrix.m);
    
    
    glBindTexture(GL_TEXTURE_2D, self.texture.texture);
    
    glDrawElements(GL_TRIANGLES, self.buffer.indiciesCount, GL_UNSIGNED_INT, 0);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    glBindVertexArrayOES(0);
}

#pragma mark - Geometry


- (GLKMatrix4)transformMatrix
{
    float xScale = self.bounds.size.width;
    float yScale = self.bounds.size.height;
    float zScale = 0.5*[self zScaleForDepthNormalization:[self.presentationMeshTransform depthNormalization]];
    
    float invXScale = xScale == 0.0f ? 1.0f : 1.0f/xScale;
    float invYScale = yScale == 0.0f ? 1.0f : 1.0f/yScale;
    float invZScale = zScale == 0.0f ? 1.0f : 1.0f/zScale;
    
    
    CATransform3D m = self.supplementaryTransform;
    GLKMatrix4 matrix = GLKMatrix4Identity;
    
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(-0.5f, -0.5f, 0.0f), matrix);
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(xScale, yScale, zScale), matrix);
    
    // at this point we're in a "point-sized" world,
    // the translations and projections will behave correctly
    
    matrix = GLKMatrix4Multiply(GLKMatrix4Make(m.m11, m.m12, m.m13, m.m14,
                                               m.m21, m.m22, m.m23, m.m24,
                                               m.m31, m.m32, m.m33, m.m34,
                                               m.m41, m.m42, m.m43, m.m44), matrix);
    
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(invXScale, invYScale, invZScale), matrix);
    matrix = GLKMatrix4Multiply(GLKMatrix4MakeScale(2.0, -2.0, 1.0), matrix);
    
    return matrix;
}

- (GLKVector3)positionScaleWithDepthNormalization:(NSString *)depthNormalization
{
    float xScale = self.bounds.size.width;
    float yScale = self.bounds.size.height;
    float zScale = [self zScaleForDepthNormalization:depthNormalization];
    
    return GLKVector3Make(xScale, yScale, zScale);
}


- (float)zScaleForDepthNormalization:(NSString *)depthNormalization
{
    static NSDictionary *dictionary;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = @{
                       kBCDepthNormalizationWidth   : ^float(CGSize size) { return size.width; },
                       kBCDepthNormalizationHeight  : ^float(CGSize size) { return size.height; },
                       kBCDepthNormalizationMin     : ^float(CGSize size) { return MIN(size.width, size.height); },
                       kBCDepthNormalizationMax     : ^float(CGSize size) { return MAX(size.width, size.height); },
                       kBCDepthNormalizationAverage : ^float(CGSize size) { return 0.5 * (size.width + size.height); },
                       };
    });
    
    float (^block)(CGSize size) = dictionary[depthNormalization];
    
    if (block) {
        return block(self.bounds.size);
    }
    
    return 0.0;
}

#pragma mark - Warning Methods

// A simple warning for convenience's sake

- (void)addSubview:(UIView *)view
{
    [super addSubview:view];
    NSLog(@"Warning: do not add a subview directly to BCMeshTransformView. Add it to contentView instead.");
}

@end
