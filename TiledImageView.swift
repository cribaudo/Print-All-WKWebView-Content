//
//  TiledImageView.swift
//  iPhemeris
//
//  Created by Clifford Ribaudo on 12/30/24.
//  Copyright © 2024 Clifford Ribaudo. All rights reserved.
//
import Foundation

#if os(macOS)
@objcMembers class TiledImageView: NSView
{
    var imageTiles: Array<NSArray> = []
    override var isFlipped: Bool { return true }
    
    init(frame:CGRect, imgTiles: Array<NSArray>)
    {
        super.init(frame: NSRectFromCGRect(frame))
        imageTiles = imgTiles
    }
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    func printWithPrintInfo(_ pi: NSPrintInfo)
    {
        let po = NSPrintOperation.init(view: self, printInfo:pi)
        po.run()
    }

    override func draw(_ rect: CGRect)
    {
        for imgData in imageTiles {
            let drawRect = (imgData[0] as! NSValue).rectValue
            let img = imgData[1] as! NSImage
            img.draw(in: drawRect)
        }
    }
}
#elseif os(iOS)
@objcMembers class TiledImageView: UIView
{
    var imageTiles: Array<NSArray> = []
    init(frame:CGRect, imgTiles: Array<NSArray>)
    {
        super.init(frame:frame)
        imageTiles = imgTiles
    }
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    //override var isFlipped: Bool { return true }
    
    override func draw(_ rect: CGRect)
    {
        for imgData in imageTiles {
            let drawRect = (imgData[0] as! NSValue).cgRectValue
            let img = imgData[1] as! UIImage
            img.draw(in: drawRect)
        }
    }

    //
    //  Will return image where scale uses screen resolution and size in pixels will be larger
    //  than the physical bounds of the screen. Retina is higher than logical bounds by 2 or 4
    //  dpi = 72 = scale of 1
    //
    func imageFromView() -> UIImage
    {
        return self.imageFromViewAt(scale: 0)
    }
    
    //
    //  Use this when getting images for printing and set scale to 1
    //
    func imageFromViewAt(scale: CGFloat) -> UIImage
    {
        var snapshotImage: UIImage
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, scale)
        
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
            snapshotImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        return snapshotImage;
    }
}
#endif
