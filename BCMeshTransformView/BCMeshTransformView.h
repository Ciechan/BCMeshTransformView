//
//  BCMeshTransformView.h
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BCMeshTransform.h"
#import "BCMutableMeshTransform+Convenience.h"

@interface BCMeshTransformView : UIView

// Animatable. Animation won't fire for incompatible mesh transforms.
// Animation will always begin from current state, even if UIViewAnimationOptionBeginFromCurrentState
// option is not set. Defaults to identity transform with 4 vertices.
@property (nonatomic, copy) BCMeshTransform *meshTransform;


// The contents of contentView will get rasterized as an image that will be used
// to texture the generated mesh. Don't add subviews to BCMeshTransformView directly,
// use this contentView instead. Do not modify the properties of a contentView.
@property (nonatomic, strong, readonly) UIView *contentView;


// Direction of light. Doesn't have to be normalized. Defaults to {0.0, 0.0, 1.0}.
@property (nonatomic) BCPoint3D lightDirection;

// The influence of diffuse lighting on a mesh. The value of 1.0f is 100% diffuse light, no ambient
// light whatsoever. The value of 0.0f is pure ambient light. Defaults to 1.0f.
@property (nonatomic) float diffuseLightFactor;


// Supplementary transform applied to mesh vertices. Can be used to apply perspective transform.
// Defualts to CATransform3DIdentity.
@property (nonatomic) CATransform3D supplementaryTransform;

@end
