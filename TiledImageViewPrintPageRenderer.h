//
//  TiledImageViewPrintPageRenderer.h
//
//  Created by Clifford Ribaudo on 4/16/21.
//  Copyright © 2021 Clifford Ribaudo. MIT License.
//
#import <UIKit/UIKit.h>
#import "TiledImageView.h"

@interface TiledImageViewPrintPageRenderer : UIPrintPageRenderer
{
    CGFloat _scale;
    UIImage *_scaledImage;
    BOOL    _portraitOrientation;
}
@property (nonatomic, strong) UIImage *fullImage;
@end
