//
//  IphemerisWKWebView.m
//  iPhemeris
//
//  Created by Clifford Ribaudo on 2/15/21.
//  Copyright © 2021 Clifford Ribaudo. MIT License.
//
//  Handle Right Mouse clicks for printing
//
#import "IphemerisWKWebView.h"

#ifdef _IOS_
#include "TiledImageViewPrintPageRenderer.h"
#endif

@implementation IphemerisWKWebView

-(id)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    self = [super initWithFrame:frame configuration:configuration];
    if(self) {
        _currentZoomScale = -1.0;
#if defined(_IPHEMERIS_MAC_) && defined(DEBUG)
        //[self.configuration.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
#endif
    }
    return self;
}

-(void)print:(id)sender
{
    [self print];
}

#ifdef _MAC_
//****************************************************************************************************
//                                           MacOS Functions
//****************************************************************************************************
-(void)mouseDown:(NSEvent *)event
{
    if(event.modifierFlags & NSEventModifierFlagControl)
        return [self rightMouseDown:event];
    
    [super mouseDown:event];
}

-(void)rightMouseDown:(NSEvent *)theEvent
{
#ifdef SHOW_INSPECTOR
    [super rightMouseDown:theEvent];
#else
    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@"Print Menu"];
    [rightClickMenu insertItemWithTitle:NSLocalizedString(@"Print", nil) action:@selector(print:) keyEquivalent:@"" atIndex:0];
    
    [NSMenu popUpContextMenu:rightClickMenu withEvent:theEvent forView:self];
#endif
}

-(void)print
{
    if(_startingPrintingAction)
        _startingPrintingAction();
    
    // These settings work and allow the user to either print
    NSPrintInfo *pInfo = [NSPrintInfo sharedPrintInfo];
    pInfo.orientation = NSPaperOrientationLandscape;
    pInfo.verticallyCentered = NO;
    pInfo.horizontallyCentered = NO;
    pInfo.bottomMargin = pInfo.topMargin = 72/2.0;          // There are 72 points per inch
    pInfo.leftMargin = pInfo.rightMargin = 72/2.0;
    
    if(_ephemerisPage) {                                    // Ephemeris Pages fit in one page row but can extend to right onto other pages.
        pInfo.horizontalPagination = NSAutoPagination;
        pInfo.verticalPagination = NSFitPagination;
        pInfo.horizontallyCentered = NO;
    }
    else {
        pInfo.horizontallyCentered = YES;                   // Calendar Pages fit in one page column but can extend down to other pages.
        pInfo.horizontalPagination = NSFitPagination;
        pInfo.verticalPagination = NSAutoPagination;
    }
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, .25 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [self HTMLPageMetrics:^(CGSize htmlSize, CGSize visibleSize, NSError *error)
        {
            NSMutableArray<NSArray *> *imgTileData = [NSMutableArray new];
            [self imageTilesForHTMLPage:htmlSize visbleRect:visibleSize imgData:imgTileData completionHandler:^(NSError *error) {
                if(!error) {
                    TiledImageView *tiv = [[TiledImageView alloc] initWithFrame:CGRectMake(0, 0, htmlSize.width, htmlSize.height) imageTiles:imgTileData];
                    [tiv printWithPrintInfo:pInfo];
                }
                if(self->_donePrintingAction)
                    self->_donePrintingAction();
            }];
        }];
    });
}

#else
//****************************************************************************************************
//                                             iOS Functions
//***************************************************************************************************
-(void)printEphemeris
{
    if(_startingPrintingAction)
        _startingPrintingAction();
    
    self.scrollView.zoomScale = 1.0;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    CGSize pageSize = self.scrollView.contentSize;
    CGSize visibleSize = self.bounds.size;
    
    NSMutableArray<NSArray *> *imgTileData = [NSMutableArray new];
    //
    //  Give page time to redraw in case _startingPrintAction() did anything time consuming.
    //
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [self imageTilesForHTMLPage:pageSize visbleRect:visibleSize imgData:imgTileData completionHandler:^(NSError *error)
        {
            if(!error) {
                TiledImageView *tiv = [[TiledImageView alloc] initWithFrame:CGRectMake(0, 0, pageSize.width, pageSize.height) imageTiles:imgTileData];
                
                TiledImageViewPrintPageRenderer *pr = [TiledImageViewPrintPageRenderer new];
                pr.fullImage = [tiv imageFromView];
                
                UIPrintInfo *pi = [UIPrintInfo printInfo];
                pi.jobName = @"iPhemeris";
                pi.orientation = UIPrintInfoOrientationLandscape;
                pi.outputType = UIPrintInfoOutputGeneral;
    
                UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
                pic.printInfo = pi;
                pic.printPageRenderer = pr;
                [pic presentAnimated:YES completionHandler:nil];
            }
            if(self->_donePrintingAction)
                self->_donePrintingAction();
        }];
    });
}

//
//  Grab image of entire WKWebView content (including offscreen parts) and pass to completion handler.
//  Good for Share functions.
//
-(void)snapShotImageWithCompletionHandler:(void (^)(UIImage *img))completionHandler
{
    self.scrollView.zoomScale = 1.0;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    CGSize pageSize = self.scrollView.contentSize;
    CGSize visibleSize = self.bounds.size;
    
    NSMutableArray<NSArray *> *imgTileData = [NSMutableArray new];
    
    // Give page a little time to adjust zoomScale
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, .25 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [self imageTilesForHTMLPage:pageSize visbleRect:visibleSize imgData:imgTileData completionHandler:^(NSError *error)
        {
            if(!error) {
                TiledImageView *tiv = [[TiledImageView alloc] initWithFrame:CGRectMake(0, 0, pageSize.width, pageSize.height) imageTiles:imgTileData];
                completionHandler([tiv imageFromViewAtScale:1.0]);  // Scale = bounds not screen pixel resolution
            }
            self.scrollView.showsVerticalScrollIndicator = YES;
            self.scrollView.showsHorizontalScrollIndicator = YES;
        }];
    });
}
#endif
@end
