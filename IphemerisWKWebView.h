//
//  IphemerisWKWebView.h
//  iPhemeris
//
//  Created by Clifford Ribaudo on 2/15/21.
//  Copyright © 2021 Clifford Ribaudo. MIT License.
//
#import <WebKit/WebKit.h>
#import "WKWebView+UtilityFunctions.h"
#import "HTMLPage.h"

@interface IphemerisWKWebView : WKWebView

@property (nonatomic, assign) BOOL chartReport;
@property (nonatomic, assign) BOOL ephemerisPage;
@property (nonatomic, assign) BOOL calendarPage;
@property (nonatomic, assign) CGPoint currentScrollXY;
@property (nonatomic, assign) CGFloat currentZoomScale;
@property (nonatomic, assign) CGRect currentContentOffset;
@property (nonatomic, nullable, strong) HTMLPage *html;

//  So that User can provide block to do something when printing starts or stops.
//  SkyNow uses it to stop/start timer when WebView starts/finishes printing
@property (strong) void (^ _Nullable startingPrintingAction)(void);
@property (strong) void (^ _Nullable donePrintingAction)(void);

-(void)print:(id _Nullable)sender;
-(void)printChart;
-(void)printEphemeris;

#ifdef _IOS_
-(void)snapShotImageWithCompletionHandler:(void (^_Nonnull)(UIImage * _Nullable img))completionHandler;
#endif
@end
