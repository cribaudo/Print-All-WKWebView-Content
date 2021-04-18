//
//  TiledImageViewPrintPageRenderer.m
//  iPhemeris
//
//  Created by Clifford Ribaudo on 4/16/21.
//  Copyright © 2021 Clifford Ribaudo. All rights reserved.
//
#import "TiledImageViewPrintPageRenderer.h"
#import "UIImage+Resize.h"

@implementation TiledImageViewPrintPageRenderer

-(id)init
{
    self = [super init];
    if(self) {
        _scale = 1.0;
    }
    return self;
}

-(NSInteger)numberOfPages
{
    //
    //  Determine if orientation is Portrait or Landscape and scale to fit portrait 1 wide and x down
    //  and Landscape 1 high and x wide.
    //
    _portraitOrientation = (MIN(_fullImage.size.width, _fullImage.size.height) == _fullImage.size.width) ? YES : NO;
    if(_portraitOrientation)
        _scale = self.printableRect.size.width / _fullImage.size.width;
    else
        _scale = self.printableRect.size.height / _fullImage.size.height;
    
    // If image is smaller than printable rect don't scale up.
    _scale = (_scale > 1) ? 1.0 : _scale;
    
    if(_scale < 1) {
        CGSize scaledSize = CGSizeMake(round(_fullImage.size.width * _scale), round(_fullImage.size.height * _scale));
        _scaledImage = [_fullImage imageWithSize:scaledSize];
    }
    else
        _scaledImage = _fullImage;
    
    CGFloat fullWidth = _scaledImage.size.width;
    CGFloat fullHeight = _scaledImage.size.height;
    
    NSInteger pageCnt = 0;
    while(YES)
    {
        pageCnt++;
        if(_portraitOrientation) {
            fullHeight -= round(self.printableRect.size.height);
            if(fullHeight < 0) break;
        }
        else {
            fullWidth -= round(self.printableRect.size.width);
            if(fullWidth < 0) break;
        }
    }
    return pageCnt;
}

-(void)drawPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)printableRect
{
    printableRect.origin.x = round(printableRect.origin.x);
    printableRect.origin.y = round(printableRect.origin.y);
    printableRect.size.width = round(printableRect.size.width);
    printableRect.size.height = round(printableRect.size.height);
    
    CGRect cropRect;
    cropRect.origin.x = 0;
    cropRect.origin.y = 0;
    cropRect.size = printableRect.size;
    
    if(_portraitOrientation)
    {
        CGFloat remainingHeight;
        printableRect.origin.y += (printableRect.size.height * pageIndex);
        remainingHeight = _scaledImage.size.height - cropRect.origin.y;
        
        if(remainingHeight < printableRect.size.height)
            printableRect.size.height = remainingHeight;
    }
    else {
        cropRect.origin.x = (printableRect.size.width * pageIndex);
        cropRect.size.width = _scaledImage.size.width - cropRect.origin.x;
        
        if(cropRect.size.width > printableRect.size.width)
            cropRect.size.width = printableRect.size.width;
    }
    // Get the portion of the scaled image that should print on the current page
    UIImage *imageForPage = [_scaledImage subImageForRect:cropRect atScale:0.0];

    // Print that image portion on the current page
    [imageForPage drawAtPoint:printableRect.origin];
}
@end
