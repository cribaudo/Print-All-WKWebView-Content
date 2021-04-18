//
//  WKWebView+UtilityFunctions.h
//
//  Created by Clifford Ribaudo on 12/24/20.
//  Copyright © 2020 Clifford Ribaudo. MIT License.
//
#import <WebKit/WebKit.h>
#import "TiledImageView.h"

@interface WKWebView (UtilityFunctions)

-(void)HTMLPageMetrics:(void (^)(CGSize htmlDocSize, CGSize visibleSize, NSError *error))completionHandler;
-(void)currentScrollXY:(void (^)(float x, float y, NSError *error))completionHandler;
-(void)scrollHTMLTo:(float)x topY:(float)y completionHandler:(void (^)(NSError *error))completionHandler;
-(void)imageTilesForHTMLPage:(CGSize)pageSize visbleRect:(CGSize)visibleRect imgData:(NSMutableArray<NSArray *> *)tileData completionHandler:(void (^)(NSError *error))completionHandler;
-(void)imageTile:(CGRect)imgRect fromPageOfSize:(CGSize)pageSize inViewOfSize:(CGSize)viewSize completionHandler:(void (^)(IMAGE_OBJ *tileImage, NSError *error))completionHandler;
@end
