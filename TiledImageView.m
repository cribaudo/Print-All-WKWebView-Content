//
//  TiledImageView.m
//  iPhemeris
//
//  Created by Clifford Ribaudo on 12/21/20.
//  Copyright © 2021 Clifford Ribaudo. MIT License.
//
#import "TiledImageView.h"

@implementation TiledImageView

-(instancetype)initWithFrame:(CGRect)frame imageTiles:(NSArray<NSArray *> *)imageTiles
{
#ifdef _MACOS_
    self = [super initWithFrame:NSRectFromCGRect(frame)];
#else
    self = [super initWithFrame:frame];
#endif
    if(self) {
        _imageTiles = imageTiles;
    }
    return self;
}
-(BOOL)isFlipped {return YES;}

-(void)printWithPrintInfo:(PRINTINFO_OBJ *)pi
{
#ifdef _MACOS_
    NSPrintOperation *po = [NSPrintOperation printOperationWithView:self];
    po.printInfo = pi;
    [po runOperation];
#endif
}

- (void)drawRect:(CGRect)rect
{
    for(NSArray *imgData in _imageTiles)
    {
#ifdef _MACOS_
        CGRect drawRect = ((NSValue *)imgData[0]).rectValue;
#else
        CGRect drawRect = ((NSValue *)imgData[0]).CGRectValue;
#endif
        IMAGE_OBJ *img = imgData[1];
        [img drawInRect:drawRect];
    }
}

#ifdef _IOS_
//
//  iOS Specific Functions to get Images from full tiledView.
//

//
//  Will return image where scale uses screen resolution and size in pixels will be larger
//  than the physical bounds of the screen. Retina is higher than logical bounds by 2 or 4
//  dpi = 72 = scale of 1
//
-(UIImage *)imageFromView
{
    return [self imageFromViewAtScale:0];
}

//
//  Use this when getting images for printing and set scale to 1
//
-(UIImage *)imageFromViewAtScale:(CGFloat)scale
{
    UIImage *snapshotImage;
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, scale);
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
        snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}
#endif
@end
