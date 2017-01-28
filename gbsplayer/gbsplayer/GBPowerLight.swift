//
//  GBPowerLight.swift
//  gbsplayer
//
//  Created by Owner on 1/28/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


let POWERLIGHT_IMAGE_FILENAME = "gb-powerlight.png"
let POWERLIGHT_IMAGE: NSImage! = Bundle.main.image(forResource: POWERLIGHT_IMAGE_FILENAME)

class GBPowerLight: NSView {

    private var image: NSImage = POWERLIGHT_IMAGE
    
    var state: PowerLightState = .Off {
        didSet {
            let newHue: Float
            switch state {
            case .Off:
                newHue = 0.0
            case .Red:
                newHue = 0.0
            case .Yellow:
                newHue = Float(60/180*3.14)
            case .Green:
                newHue = Float(120/180*3.14)
            }
            
            //@todo cache images on startup
            if let image = adjustImage(img: POWERLIGHT_IMAGE, hue: newHue) {
                self.image = image
                self.needsDisplay = true
            }
        }
    }
    
    
    enum PowerLightState {
        case Off
        case Red
        case Yellow
        case Green
    }
    
    func adjustImage(img: NSImage, hue: Float) -> NSImage? {
        // Convert the input image into a Core Image-friendly format
        guard let tiff = img.tiffRepresentation else {
            return nil
        }
        let inputImage = CIImage(data: tiff)
        
        // Create the hue adjust filter
        guard let hueAdjust = CIFilter(name: "CIHueAdjust") else {
            return nil
        }
        hueAdjust.setValue(inputImage, forKey: kCIInputImageKey)
        hueAdjust.setValue(NSNumber(value: hue), forKey: kCIInputAngleKey)
        
        // Run the hue adjustment
        guard let outputImage = hueAdjust.value(forKey: kCIOutputImageKey) as? CIImage else {
            return nil
        }
        
        // Convert the Core Image output to an NSImage
        let resultImage = NSImage(size: outputImage.extent.size)
        let rep = NSCIImageRep(ciImage: outputImage)
        resultImage.addRepresentation(rep)
        
        return resultImage
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        image.draw(in: dirtyRect)
    }
    
}
