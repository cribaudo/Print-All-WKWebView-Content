//
//  WKWebView+UtilityFunctions.m
//
//  Created by Clifford Ribaudo on 12/24/20.
//  Copyright © 2020 Clifford Ribaudo. MIT License
//
//  Works with MacOS v10.14+ and iOS 13+
//
#import "WKWebView+UtilityFunctions.h"

@implementation WKWebView (UtilityFunctions)
//
//  Returns via Completion Handler:
//      htmlDocSize - The size of the entire <HTML> element, visible or not
//      visibleSize - The visible dimensions of the page, essentially WKWebView bounds minus HTML scroll bar dimensions
//
-(void)HTMLPageMetrics:(void (^)(CGSize htmlDocSize, CGSize visibleSize, NSError *error))completionHandler
{
    //
    //  Anonymous Function - gets Size of entire HTML element and visible size.
    //  Result String = Full X, Full Y, Visible X, Visible Y
    //
    NSString *jsGetPageMetrics = @"(function(){return document.documentElement.scrollWidth + ',' + document.documentElement.scrollHeight + ',' + document.documentElement.clientWidth + ',' +document.documentElement.clientHeight;})();";
    
    // Execute JS in WKWebView
    [self evaluateJavaScript:jsGetPageMetrics completionHandler:^(id result, NSError *error)
    {
        CGSize htmlSize = CGSizeMake(0, 0);
        CGSize visibleSize = CGSizeMake(0, 0);
        
        if(!error && result)
        {
            NSArray<NSString *> *data = [[NSString stringWithFormat:@"%@", result] componentsSeparatedByString:@","];
            htmlSize = CGSizeMake([data[0] floatValue], [data[1] floatValue]);
            visibleSize = CGSizeMake([data[2] floatValue], [data[3] floatValue]);
        }
        else
            NSLog(@"JS error getting page metrics: %@", error.description);
        
        completionHandler(htmlSize, visibleSize, error);
    }];
}

//
//  Get <HTML> element current scroll position (x,y) and return to completeion handler:
//      x = document.documentElement.scrollLeft
//      y = document.documentElement.scrollTop
//
-(void)currentScrollXY:(void (^)(float X, float Y, NSError *error))completionHandler
{
    NSString *jsGetPageMetrics = @"(function(){return document.documentElement.scrollLeft + ',' + document.documentElement.scrollTop;})();";
    
    // Execute JS in WKWebView
    [self evaluateJavaScript:jsGetPageMetrics completionHandler:^(id result, NSError *error) {
        if(!error && result)
        {
            NSArray<NSString *> *data = [[NSString stringWithFormat:@"%@", result] componentsSeparatedByString:@","];
            completionHandler([data[0] floatValue], [data[1] floatValue], error);
        }
        else {
            NSLog(@"JS error getting page metrics: %@", error.localizedDescription);
            completionHandler(0, 0, error);
        }
    }];
}

//
//  Scroll the current HTML page to x, y using scrollTo(x,y) on the <HTML> element
//  Optional Completion Handler to do something when scroll finished
//
-(void)scrollHTMLTo:(float)x topY:(float)y completionHandler:(void (^)(NSError *error))completionHandler
{
    NSString *js = [NSString stringWithFormat:@"document.documentElement.scrollTo(%0.f, %0.f);", x, y];
    
    // Execute JS in WKWebView
    [self evaluateJavaScript:js completionHandler:^(id result, NSError *error)
    {
        // Prevent calling handler before WKWebView has actually scrolled.
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, .35 * NSEC_PER_SEC);
        dispatch_after(delay, dispatch_get_main_queue(), ^{
            if(completionHandler) completionHandler(error);
        });
        if(error) NSLog(@"JS error scrollTo %@", error.localizedDescription);
    }];
}

//
//  Called Recursively until tiles are obtained for the entire pageRect.
//  Tiles are the size of visibleRect (WKWebView.bounts) but can be smaller.
//  tileData - Array of arrays holding CGRect, Img.
//
-(void)imageTilesForHTMLPage:(CGSize)pageSize visbleRect:(CGSize)visibleSize imgData:(NSMutableArray<NSArray *> *)tileData completionHandler:(void (^)(NSError *error))completionHandler
{
    __block CGRect currentRect;                         // In coordinates of pageSize (full).
    
    if(tileData.count == 0) {                           // No image tiles yet. Start at top left of html page for visible WKWebView bounds
        currentRect.origin.x = currentRect.origin.y = 0.0;
        currentRect.size = visibleSize;
    }
    else {
        NSArray *lastTile = [tileData lastObject];      // Calculate what the next tile rect is or call handler if done.
        CGRect lastTileRect;
        
#ifdef _MACOS_
        lastTileRect = ((NSValue *)lastTile[0]).rectValue;
#else
        lastTileRect = ((NSValue *)lastTile[0]).CGRectValue;
#endif
        // Check if anything more to get to right of last tile
        if((lastTileRect.origin.x + lastTileRect.size.width) < pageSize.width)
        {
            currentRect.origin.x = lastTileRect.origin.x + lastTileRect.size.width;     // Next x to right of last tile
            currentRect.origin.y = lastTileRect.origin.y;                               // Works on all rows
            currentRect.size.height = lastTileRect.size.height;
            
            currentRect.size.width = pageSize.width - currentRect.origin.x;             // Get width of next tile to right of last
            if(currentRect.size.width > visibleSize.width)                              // If more tiles to right use visible width
                currentRect.size.width = visibleSize.width;
        }
        else if((lastTileRect.origin.y + lastTileRect.size.height) < pageSize.height)   // New Row
        {
            currentRect.origin.x = 0;                                                   // Reset x back to left side of hmtl
            currentRect.size.width = visibleSize.width;                                 // Reset width back to view width
            
            currentRect.origin.y = lastTileRect.origin.y + lastTileRect.size.height;    // Get y below last row
            currentRect.size.height = pageSize.height - currentRect.origin.y;
            if(currentRect.size.height > visibleSize.height)                            // If more rows below use row height
                currentRect.size.height = visibleSize.height;
        }
        else {
            completionHandler(nil);
            return;
        }
    }
    [self imageTile:currentRect fromPageOfSize:pageSize inViewOfSize:visibleSize completionHandler:^(IMAGE_OBJ *tileImage, NSError *error)
    {
        if(error || !tileImage) {
            NSLog(@"Error getting image tiles %@", error.description);
            completionHandler(error);
            return;
        }
#ifdef _MACOS_
        [tileData addObject:@[[NSValue valueWithRect:NSRectFromCGRect(currentRect)], tileImage]];
#else
        [tileData addObject:@[[NSValue valueWithCGRect:currentRect], tileImage]];
#endif
        [self imageTilesForHTMLPage:(CGSize)pageSize visbleRect:(CGSize)visibleSize imgData:(NSMutableArray<NSArray *> *)tileData completionHandler:completionHandler];
    }];
}

#ifdef _MACOS_
//
//  Mac Version can use JS in WKWebView to get dimensions and scroll around page. iOS can't due to several issues with
//  WKWebView return incorrect page dimensions via JS (a bug) and consequent incorrect scrolling. iOS works with
//  WKWebView.scrollView.
//
//  ImgRect = location of rect in full page size. Has to be translated into what is visible and where.
//  pageSize = Full size of HTML page, visible or not.
//  viewSize = essentially the wkwebview.bounds.size - HTML scroll bars.
//
-(void)imageTile:(CGRect)imgRect fromPageOfSize:(CGSize)pageSize inViewOfSize:(CGSize)viewSize completionHandler:(void (^)(IMAGE_OBJ *tileImage, NSError *error))completionHandler
{
    float x = imgRect.origin.x;     // Always do this to make the desired rect visible in the rect of viewSize
    float y = imgRect.origin.y;
    
    CGRect rectToGetFromView;
    
    rectToGetFromView.origin.x = 0;
    rectToGetFromView.origin.y = 0;
    rectToGetFromView.size = imgRect.size;
    
    // If img is smaller than the viewport, determine where it is after scroll
    if(imgRect.size.width < viewSize.width)
        rectToGetFromView.origin.x = viewSize.width - imgRect.size.width;

    if(imgRect.size.height < viewSize.height)
        rectToGetFromView.origin.y = viewSize.height - imgRect.size.height;
    
    [self scrollHTMLTo:x topY:y completionHandler:^(NSError *error)
    {
        if(!error) {
            WKSnapshotConfiguration *sc = [WKSnapshotConfiguration new];
            sc.rect = rectToGetFromView;
            [self takeSnapshotWithConfiguration:sc completionHandler:^(IMAGE_OBJ *img, NSError *error)
            {
                if(error) NSLog(@"Error snapshotting image tile: %@", error.description);
                completionHandler(img, error);
            }];
        }
        else {
            NSLog(@"Error scrolling for next image tile %@", error.description);
            completionHandler(nil, error);
        }
    }];
}
#else
// ********************* IOS Version *********************
//  Made necessary by WKWebView bug on iOS that doesn't properly return size of <html> or <body> causing issues with
//  JS Code to scroll portions of a page into view. So on iOS we do the same thing by manipulating the UIScroll View.
//
//
//  ImgRect = location of rect in WKWebView.scrollView.content. Has to be translated into what is visible and where.
//  ScrollView works differently and will show blank region if scrollTo is set to something that includes unused or invalid area?
//
//  contentSize = Full size of HTML page. A WKWebView bug prevents obtaining correct value via JS, so instead use scrollView's contentSize.
//  viewSize = essentially the wkwebview.bounds.size - HTML scroll bars.
//
-(void)imageTile:(CGRect)imgRect fromPageOfSize:(CGSize)contentSize inViewOfSize:(CGSize)viewSize completionHandler:(void (^)(IMAGE_OBJ *tileImage, NSError *error))completionHandler
{
    float x = imgRect.origin.x;     // Always do this to make the desired rect visible in the rect of viewSize
    float y = imgRect.origin.y;
    
    CGRect rectToGetFromView;
    
    rectToGetFromView.origin.x = 0;
    rectToGetFromView.origin.y = 0;
    rectToGetFromView.size = imgRect.size;
    
    //  If img is smaller than the viewport, determine how much to scroll to slide
    //  it all into view and where in the view it will be after scroll.
    if(imgRect.size.width < viewSize.width) {
        x = contentSize.width - viewSize.width;
        rectToGetFromView.origin.x = viewSize.width - imgRect.size.width;
    }
    if(imgRect.size.height < viewSize.height) {
        y = contentSize.height - viewSize.height;
        rectToGetFromView.origin.y = viewSize.height - imgRect.size.height;
    }
    
    [self.scrollView setContentOffset:CGPointMake(x, y) animated:NO];
    //NSLog(@"Rect to Get: %@", NSStringFromCGRect(imgRect));
    //NSLog(@"Scroll to: {{%.0f, %.0f of {%.0f, %.0f}}", x, y, contentSize.width, contentSize.height);
    //NSLog(@"Grab rect: %@", NSStringFromCGRect(rectToGetFromView));
    //NSLog(@" ");
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, .35 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        WKSnapshotConfiguration *sc = [WKSnapshotConfiguration new];
        sc.rect = rectToGetFromView;
        [self takeSnapshotWithConfiguration:sc completionHandler:^(IMAGE_OBJ *img, NSError *error)
        {
            if(error) NSLog(@"Error snapshotting image tile: %@", error.description);
            completionHandler(img, error);
        }];
    });
}
#endif
@end
