//
//  Util.swift
//  gbsplayer
//
//  Created by Owner on 1/29/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


/// Adjust some color parameters of an image.
func adjustImageColors(image: NSImage, hue: Float, saturation: Float,
                       brightness: Float, contrast: Float) -> NSImage?
{
    // Convert the input image into a Core Image-friendly format
    guard let tiff = image.tiffRepresentation else {
        return nil
    }
    guard let inputImage = CIImage(data: tiff) else {
        return nil
    }
    
    // Create the hue adjust filter
    guard let hueAdjustFilter = CIFilter(name: "CIHueAdjust") else {
        return nil
    }
    hueAdjustFilter.setValue(inputImage, forKey: kCIInputImageKey)
    hueAdjustFilter.setValue(NSNumber(value: hue), forKey: kCIInputAngleKey)
    
    // Run the hue adjustment
    guard let hueAdjusted = hueAdjustFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
        return nil
    }
    
    // Create the color adjust filter
    guard let colorAdjustFilter = CIFilter(name: "CIColorControls") else {
        return nil
    }
    colorAdjustFilter.setValue(hueAdjusted, forKey: kCIInputImageKey)
    colorAdjustFilter.setValue(NSNumber(value: saturation), forKey: kCIInputSaturationKey)
    colorAdjustFilter.setValue(NSNumber(value: brightness), forKey: kCIInputBrightnessKey)
    colorAdjustFilter.setValue(NSNumber(value: contrast), forKey: kCIInputContrastKey)
    
    // Run the color adjustment
    guard let output = colorAdjustFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
        return nil
    }
    
    // Convert the Core Image output to an NSImage
    let resultImage = NSImage(size: output.extent.size)
    let rep = NSCIImageRep(ciImage: output)
    resultImage.addRepresentation(rep)
    
    return resultImage
}
