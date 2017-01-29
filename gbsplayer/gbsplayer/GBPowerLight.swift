//
//  GBPowerLight.swift
//  gbsplayer
//
//  Created by Owner on 1/28/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


let POWERLIGHT_IMAGE_FILENAME = "gb-powerlight.png"
let POWERLIGHT_BASE_IMAGE: NSImage! = Bundle.main.image(forResource: POWERLIGHT_IMAGE_FILENAME)
let POWERLIGHT_BASE_STATE = GBPowerLight.PowerLightState.Red
// Map each state to its desired (hue, saturation, brightness, contrast) adjustments
let COLOR_PARAMS_MAP: [GBPowerLight.PowerLightState : (Float, Float, Float, Float)] =
    [.Off: (0.0, 0.0, 0.0, 0.8), .Red: (0.0, 1.0, 0.0, 1.0),
     .Yellow: (1/3*3.14, 1.4, 0.1, 1.3), .Green: (2/3*3.14, 1.0, 0.0, 1.0)]


/// A Game Boy power light, with adjustable color
/// Nonstandard (non-red) color images are created and cached in memory at runtime - just provide the base red image and go 
class GBPowerLight: NSView {
    enum PowerLightState {
        case Off
        case Red
        case Yellow
        case Green
    }
    
    var state = POWERLIGHT_BASE_STATE {
        didSet {
            if state != oldValue {
                self.image = getOrMakeImage(forState: state)
                self.needsDisplay = true
            }
        }
    }
    
    private var image: NSImage = POWERLIGHT_BASE_IMAGE
    private var imageCache: [PowerLightState : NSImage] = [:]
    
    
    /// Return the image corresponding with a given state, either from our cache or by making it
    private func getOrMakeImage(forState state: PowerLightState) -> NSImage {
        if let cached = imageCache[state] {
            return cached
        }
        
        let newImage = makeImage(forState: state)
        imageCache[state] = newImage
        
        return newImage
    }
    
    /// Make the image that corresponds with a given state
    private func makeImage(forState state: PowerLightState) -> NSImage {
        if state == POWERLIGHT_BASE_STATE {
            return POWERLIGHT_BASE_IMAGE
        }
        
        guard let (hueAdjust, saturationAdjust, brightnessAdjust, contrastAdjust) = COLOR_PARAMS_MAP[state] else {
            return POWERLIGHT_BASE_IMAGE
        }
        
        guard let adjustedImage = adjustImageColors(image: POWERLIGHT_BASE_IMAGE, hue: hueAdjust, saturation: saturationAdjust,
                                                    brightness: brightnessAdjust, contrast: contrastAdjust) else
        {
            return POWERLIGHT_BASE_IMAGE
        }
        
        return adjustedImage
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        image.draw(in: dirtyRect)
    }
    
}
