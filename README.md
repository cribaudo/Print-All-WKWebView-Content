# Print-All-WKWebView-Content
Prints all the on and offscreen content of a WKWebView and correctly paginates. Works on both MacOS and iOS

Usage Examples

******** MacOS ********

-(void)print
{    
    // These settings work and allow the user to either print
    NSPrintInfo *pInfo = [NSPrintInfo sharedPrintInfo];
    pInfo.orientation = NSPaperOrientationLandscape;
    pInfo.verticallyCentered = NO;
    pInfo.horizontallyCentered = NO;
    pInfo.bottomMargin = pInfo.topMargin = 72/2.0;          // There are 72 points per inch
    pInfo.leftMargin = pInfo.rightMargin = 72/2.0;
    
    // User has to decide what is appropriate here
    pInfo.horizontalPagination = NSAutoPagination;
    pInfo.verticalPagination = NSFitPagination;
    pInfo.horizontallyCentered = NO;
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, .25 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [_wkWebView HTMLPageMetrics:^(CGSize htmlSize, CGSize visibleSize, NSError *error)
        {
            NSMutableArray<NSArray *> *imgTileData = [NSMutableArray new];
            [_wkWebView imageTilesForHTMLPage:htmlSize visbleRect:visibleSize imgData:imgTileData completionHandler:^(NSError *error) {
                if(!error) {
                    TiledImageView *tiv = [[TiledImageView alloc] initWithFrame:CGRectMake(0, 0, htmlSize.width, htmlSize.height) imageTiles:imgTileData];
                    [tiv printWithPrintInfo:pInfo];
                }
            }];
        }];
    });
}

******** iOS ********

-(void)printEphemeris
{    
    self.scrollView.zoomScale = 1.0;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    CGSize pageSize = self.scrollView.contentSize;
    CGSize visibleSize = self.bounds.size;
    
    NSMutableArray<NSArray *> *imgTileData = [NSMutableArray new];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [_wkWebView imageTilesForHTMLPage:pageSize visbleRect:visibleSize imgData:imgTileData completionHandler:^(NSError *error)
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
        [_wkWebView imageTilesForHTMLPage:pageSize visbleRect:visibleSize imgData:imgTileData completionHandler:^(NSError *error)
        {
            if(!error) {
                TiledImageView *tiv = [[TiledImageView alloc] initWithFrame:CGRectMake(0, 0, pageSize.width, pageSize.height) imageTiles:imgTileData];
                completionHandler([tiv imageFromViewAtScale:1.0]);  // Scale = bounds not screen pixel resolution
            }
            _wkWebView.scrollView.showsVerticalScrollIndicator = YES;
            _wkWebView.scrollView.showsHorizontalScrollIndicator = YES;
        }];
    });
}
