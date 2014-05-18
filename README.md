BCMeshTransformView
===================

`BCMeshTransformView` makes it easy to apply a mesh transform to a view hierarchy. It's inspired by a private `CALayer` property `meshTransform` and its value class `CAMeshTransform`. I **highly** recommend taking look at [the blog post on those two](http://ciechanowski.me/blog/2014/05/14/mesh-transforms/) as it explains the concepts in depth and hopefully justifies some API choices I made.


## Features

- Transforms regular UIKit view hierarchy
- Animatable with block-based `UIView` animations of meshes
- Supports directional lighting

The demo app contains a few examples of how a mesh transform works and what it can achieve.

## Installation

`BCMeshTransformView` is available via CocoaPods:

```
pod 'BCMeshTransformView'
```

Alternatively, you can copy the contents of `BCMeshTransformView` folder to your project and include `BCMeshTransformView.h`.

## Requirements

- iOS 7.0
- ARC
- GLKit framework

You may optionally include OpenGL ES framework, as this will enable [frame capturing](https://developer.apple.com/library/ios/recipes/xcode_help-debugger/articles/debugging_opengl_es_frame.html).

## Using `BCMeshTransformView`
	
```
	// create an instance
    BCMeshTransformView *meshView = [[BCMeshTransformView alloc] initWithFrame:CGRectMake(0, 0, 400, 300)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 300)];

	// add a view hierarchy to a contentView, subviews of contentView will get mesh-transformed
	[meshView.contentView addSubview:label];
	
	// apply a mesh
	meshView.meshTransform = [self simpleMeshTransform];

    [self.view addSubview:meshView];
```

Remember to add any subviews you want to get mesh-transformed to `contentView`, *not* the view itself. The class will conveniently warn when you call `addSubview:` method on its instance.

## Using `BCMeshTransform`

A mesh transform consists of two different primitives: vertices and faces.

### Vertices

A single vertex is represented by `BCMeshVertex` struct and consists of `from` and `to` fields:

```
typedef struct BCMeshVertex {
    CGPoint from;
    BCPoint3D to;
} BCMeshVertex;
```

A vertex defines mapping between the point on the surface of the view and its transformed position in the 3D space.

Both `from` and `to` field are defined in *unit coordinates*, similarly to how `anchorPoint` property of `CALayer` works.


### Faces

A face is defined by four vertices it's spanned on. Vertices are referenced by their index in the `vertices` array of a mesh transform.

```
typedef struct BCMeshFace {
    unsigned int indices[4];
} BCMeshFace;
```


## Depth Normalization

Since vertices are defined in unit coordinates specifies the missing depth scale has to be defined as a function of the other two coordinates. The `depthNormalization` parameter can be set to one of the following six constants:

```
extern NSString * const kBCDepthNormalizationNone;
extern NSString * const kBCDepthNormalizationWidth;
extern NSString * const kBCDepthNormalizationHeight;
extern NSString * const kBCDepthNormalizationMin;
extern NSString * const kBCDepthNormalizationMax;
extern NSString * const kBCDepthNormalizationAverage;
```

## Simple Mesh Transform

Here's how the simplest mesh transform actually looks like:

```
- (BCMeshTransform *)simpleMeshTransform
{
    BCMeshVertex vertices[] = {
        {.from = {0.0, 0.0}, .to= {0.5, 0.0, 0.0}},
        {.from = {1.0, 0.0}, .to= {1.0, 0.0, 0.0}},
        {.from = {1.0, 1.0}, .to= {1.0, 1.0, 0.0}},
        {.from = {0.0, 1.0}, .to= {0.0, 1.0, 0.0}},
    };
    
    BCMeshFace faces[] = {
        {.indices = {0, 1, 2, 3}},
    };
    
    return [BCMeshTransform meshTransformWithVertexCount:4
                                                vertices:vertices
                                               faceCount:1
                                                   faces:faces
                                      depthNormalization:kBCDepthNormalizationNone];
}
```


This transform will perform a very simple skew transform, and you can tweak it further by modifying positions of `to` vertices. Check out the mesh transforms in the demo app to learn how to create more complex effects.


Although `BCMeshTransform` is the default base class, the mutable counterpart, `BCMutableMeshTransform`, is much more convenient to use.

##Animations

All versions of block-based `UIView` animations are supported, **apart** from keyframe and spring animations. Animation always begins from the current state, regardless of presence of `UIViewAnimationOptionBeginFromCurrentState` flag.

For an animation to occur, the current and final meshes have to be compatible:
- they must have the same number of vertices
- they must have the same number of faces
- the faces at corresponding indexes must point to the same vertices, (their `indices` arrays must be equal)

##Lighting

`BCMeshTransformView` supports a simple lighting model in a form of diffuse lighting with pure white light:

```
@property (nonatomic) BCPoint3D lightDirection;
@property (nonatomic) float diffuseLightFactor;
```

The `lightDirection` property defines the direction of a light source in the scene. The vector doesn't have to be normalized and by default it's equal to `{0.0, 0.0, 1.0}`.

The `diffuseLightFactor` defines how much does diffuse lighting influence the general lighting of the scene. When it's equal to `1.0` the entire scene uses pure diffuse lighting, when equal to `0.0`, the scene is only lit by ambient lighting. Values in between modify the percentage accordingly.

## Supplementary Transforms

`BCMeshTransformView` supports arbitrary matrix transformations in a form of the following property:

```
@property (nonatomic) CATransform3D supplementaryTransform;
```
Every mesh vertex in the scene gets transformed with `supplementaryTransform`. The property can be used to apply perspective transform or any other common operation like rotation, translation and scale.

## Convenience Mesh Methods

Creating `BCMutableMeshTransform` from scratch is tedious so I created a few convenience methods that should make the process much more pleasant:

### Identity Mesh Transform

This method creates a mesh transform with given number of rows and columns of faces. Generated mesh is uniform and it doesn't contain any disturbances - applying it to `BCMeshView` won't have any visual effect, but it's a great start for further modifications:

```
+ (instancetype)identityMeshTransformWithNumberOfRows:(NSUInteger)rowsOfFaces
                                      numberOfColumns:(NSUInteger)columnsOfFaces;
```

### Generators

Instead of manually creating buffer storage for the default constructor, you can use the following class method:
```
+ (instancetype)meshTransformWithVertexCount:(NSUInteger)vertexCount
                             vertexGenerator:(BCMeshVertex (^)(NSUInteger vertexIndex))vertexGenerator
                                   faceCount:(NSUInteger)faceCount
                               faceGenerator:(BCMeshFace (^)(NSUInteger faceIndex))faceGenerator;
```

The blocks will be called `vertexCount` and `faceCount` times respectively.

### Map 

A very convenient map method makes it very easy to modify existing `BCMutableMeshTransform`. It's extremely useful with dense identity transforms:

```
- (void)mapVerticesUsingBlock:(BCMeshVertex (^)(BCMeshVertex vertex, NSUInteger vertexIndex))block;
```
# Caveats

* `BCMeshTransformView` is stable and works, but it's still in beta. It won't break down unexpectedly, but I haven't seriously battle tested the class, so there still might be some edge cases when something doesn't behave as intended.

* Mesh generation is computationally heavy and may be slow in Debug mode, especially on older devices. Compiling with optimizations (Release has -Os by default) should provide major improvements.

* Since rendering is OpenGL based the `BCMeshTransformView` implicitly clips its content to bounds, regardless of `clipsToBounds` property state.

* If semi-transparent faces overlap, only the frontmost one will be rendered. The original `CAMeshTransform`  z-sorts its triangles, however, I'm using a depth buffer to resolve the relative z-order of triangles.

* All animations on the subviews of `contentView` are not supported and are removed by default. Although the content of `contentView` is snapshotted automatically on any layer changes, this process takes over 16 ms so it's not efficient enough to afford snapshotting the layer on every frame.


