//
//  TiledImageViewPrintPageRenderer.swift
//  iPhemeris
//
//  Created by Clifford Ribaudo on 12/29/24.
//  Copyright © 2024 Clifford Ribaudo. All rights reserved.
//
import Foundation
import UIKit

@objc class TiledImageViewPrintPageRenderer : UIPrintPageRenderer
{
    var scale: CGFloat = 1.0
    var portraitOrientation = true
    var scaledImage = UIImage()
    
    @objc var fullImage = UIImage()
    @objc override init() {
        super.init()
    }
    
    @objc override var numberOfPages: NSInteger
    {
        //
        //  Determine if orientation is Portrait or Landscape and scale to fit portrait 1 wide and x down
        //  and Landscape 1 high and x wide.
        //
        portraitOrientation = (min(fullImage.size.width, fullImage.size.height) == fullImage.size.width) ? true : false
        
        if(portraitOrientation) {
            scale = self.printableRect.size.width / fullImage.size.width
        } else {
            scale = self.printableRect.size.height / fullImage.size.height
        }
        // If image is smaller than printable rect don't scale up.
        scale = (scale > 1) ? 1.0 : scale
        
        scaledImage = fullImage
        if(scale < 1) {
            let scaledSize = CGSizeMake(round(fullImage.size.width * scale), round(fullImage.size.height * scale))
            scaledImage =  fullImage.imageWithSize(scaledSize)!
        }
        
        var fullWidth = scaledImage.size.width
        var fullHeight = scaledImage.size.height
        var pageCnt: NSInteger = 0
        while(true) {
            pageCnt += 1
            if(portraitOrientation) {
                fullHeight -= round(self.printableRect.size.height)
                if(fullHeight < 0) { break }
            }
            else {
                fullWidth -= round(self.printableRect.size.width)
                if(fullWidth < 0) { break }
            }
        }
        return pageCnt
    }
    
    @objc override func drawPage(at pageIndex: Int, in printableRect: CGRect)
    {
        var rectToPrint = printableRect
        rectToPrint.origin.x = round(rectToPrint.origin.x);
        rectToPrint.origin.y = round(rectToPrint.origin.y);
        rectToPrint.size.width = round(rectToPrint.size.width);
        rectToPrint.size.height = round(rectToPrint.size.height);
        
        var cropRect = CGRect(origin:CGPoint(x:0, y:0), size:rectToPrint.size)

        if(portraitOrientation) {
            cropRect.origin.y = (rectToPrint.size.height * CGFloat(pageIndex))
            cropRect.size.height = scaledImage.size.height - cropRect.origin.y
            if(cropRect.size.height > printableRect.size.height) {
                cropRect.size.height = printableRect.size.height
            }
        }
        else {
            cropRect.origin.x = (printableRect.size.width * CGFloat(pageIndex))
            cropRect.size.width = scaledImage.size.width - cropRect.origin.x
            if(cropRect.size.width > printableRect.size.width) {
                cropRect.size.width = printableRect.size.width
            }
        }
        
        // Get the portion of the scaled image that should print on the current page
        let imageForPage = scaledImage.subImageForRect(cropRect, atScale: 0.0)

        // Print that image portion on the current page
        imageForPage?.draw(at: rectToPrint.origin)
    }
}
