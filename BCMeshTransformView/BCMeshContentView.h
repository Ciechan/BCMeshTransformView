//
//  BCMeshContentView.h
//  BCMeshTransformView
//
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCMeshContentView : UIView

@property (nonatomic, copy) void (^changeBlock)(void);

- (instancetype)initWithFrame:(CGRect)frame
                  changeBlock:(void (^)(void))changeBlock;

@end
