//
//  Util.swift
//  gbsplayer
//
//  Created by Owner on 1/29/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


let GAMEBOY_PALLETTE_00 = NSColor(red: 155.0/255.0, green: 188.0/255.0, blue: 15.0/255.0, alpha: 1.0)
let GAMEBOY_PALLETTE_01 = NSColor(red: 139.0/255.0, green: 172.0/255.0, blue: 15.0/255.0, alpha: 1.0)
let GAMEBOY_PALLETTE_10 = NSColor(red: 48.0/255.0, green: 98.0/255.0, blue: 48.0/255.0, alpha: 1.0)
let GAMEBOY_PALLETTE_11 = NSColor(red: 15.0/255.0, green: 56.0/255.0, blue: 15.0/255.0, alpha: 1.0)


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
