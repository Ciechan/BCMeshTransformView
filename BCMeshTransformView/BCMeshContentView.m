//
//  BCMeshContentView.m
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCMeshContentView.h"


@interface CALayer(RecursiveExecution)
- (void)bc_recursivelyExecuteBlock:(void (^)(CALayer *layer))block;
@end

@implementation CALayer(RecursiveExecution)

- (void)bc_recursivelyExecuteBlock:(void (^)(CALayer *layer))block
{
    block(self);
    for (CALayer *layer in self.sublayers) {
        [layer bc_recursivelyExecuteBlock:block];
    }
}

@end

@interface BCMeshContentView()
@property (nonatomic, strong) NSMutableSet *observedLayers;
@end

@implementation BCMeshContentView

// Array of observable CALayer keys as defined in
// https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreAnimation_guide/AnimatableProperties/AnimatableProperties.html
+ (NSArray *)observedKeys
{
    static NSArray *keys;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        keys = @[
            @"anchorPoint",
            @"backgroundColor",
            @"borderColor",
            @"borderWidth",
            @"bounds",
            @"contents",
            @"contentsRect",
            @"cornerRadius",
            @"doubleSided",
            @"frame",
            @"hidden",
            @"mask",
            @"masksToBounds",
            @"opacity",
            @"position",
            @"shadowColor",
            @"shadowOffset",
            @"shadowOpacity",
            @"shadowPath",
            @"shadowRadius",
            @"sublayers",
            @"sublayerTransform",
            @"transform",
            @"zPosition",
        ];
    });
    
    return keys;
}

- (instancetype)initWithFrame:(CGRect)frame
                  changeBlock:(void (^)(void))changeBlock
                    tickBlock:(void (^)(CADisplayLink *))tickBlock
{
    self = [super initWithFrame:frame];
    if (self) {
        self.changeBlock = changeBlock;
        self.tickBlock = tickBlock;
        self.observedLayers = [NSMutableSet set];
        
        [self registerAsObserverToLayer:self.layer];
    }
    return self;
}

- (void)dealloc
{
    for (CALayer *layer in self.observedLayers.copy) {
        [self unregisterAsObserverFromLayer:layer];
    }
}

- (void)displayLinkTick:(CADisplayLink *)displayLink
{
    self.tickBlock(displayLink);
}

- (void)registerAsObserverToLayer:(CALayer *)layer
{
    if ([self.observedLayers containsObject:layer]) {
        return;
    }
    
    for (NSString *key in [BCMeshContentView observedKeys]) {
        [layer addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
    }
    
    [self.observedLayers addObject:layer];
    
    for (CALayer *sublayer in layer.sublayers) {
        [self registerAsObserverToLayer:sublayer];
    }
}

- (void)unregisterAsObserverFromLayer:(CALayer *)layer
{
    if (![self.observedLayers containsObject:layer]) {
        return;
    }
    
    for (NSString *key in [BCMeshContentView observedKeys]) {
        [layer removeObserver:self forKeyPath:key context:NULL];
    }

    [self.observedLayers removeObject:layer];
    
    for (CALayer *sublayer in layer.sublayers) {
        [self unregisterAsObserverFromLayer:sublayer];
    }
}

- (void)didChange:(NSKeyValueChange)changeKind valuesAtIndexes:(NSIndexSet *)indexes forKey:(NSString *)key;
{
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(CALayer *)layer change:(NSDictionary *)change context:(void *)context
{
    if (![layer isKindOfClass:[CALayer class]]) {
        [super observeValueForKeyPath:keyPath ofObject:layer change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"sublayers"]) {
        NSArray *newArray = change[NSKeyValueChangeNewKey];
        
        if ([newArray isKindOfClass:[NSArray class]]) {
            for (CALayer *layer in newArray) {
                [self unregisterAsObserverFromLayer:layer];
            }
            
            for (CALayer *layer in newArray) {
                [self registerAsObserverToLayer:layer];
            }
        }
    }
    
    [self.layer bc_recursivelyExecuteBlock:^(CALayer *layer) {
        [layer removeAllAnimations];
    }];
    
    if (self.changeBlock) {
        self.changeBlock();
    }
}


@end
