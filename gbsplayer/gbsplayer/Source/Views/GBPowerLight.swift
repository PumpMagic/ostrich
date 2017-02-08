//
//  GBPowerLight.swift
//  gbsplayer
//
//  Created by Owner on 1/28/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


// Some configuration constants.
fileprivate let BASE_IMAGE_FILENAME = "powerlight.png"
fileprivate let BASE_IMAGE: NSImage! = Bundle.main.image(forResource: BASE_IMAGE_FILENAME)
fileprivate let BASE_STATE = GBPowerLight.State.Red
// Map each state to its desired (hue, saturation, brightness, contrast) adjustments from the base image
fileprivate let COLOR_PARAMS_MAP: [GBPowerLight.State : (Float, Float, Float, Float)] =
    [.Off: (0.0, 0.0, 0.0, 0.8), .Red: (0.0, 1.0, 0.0, 1.0),
     .Yellow: (1/3*3.14, 1.4, 0.1, 1.3), .Green: (2/3*3.14, 1.0, 0.0, 1.0)]


/// An LED-looking view whose appearance mimics that of a Game Boy's power light. With adjustable color.
/// Generates and caches non-red-colored images at runtime.
class GBPowerLight: NSView {
    enum State {
        case Off
        case Red
        case Yellow
        case Green
    }
    
    var state = BASE_STATE {
        didSet {
            if state != oldValue {
                handleNewState()
            }
        }
    }
    
    private var image: NSImage = BASE_IMAGE
    private var imageCache: [State : NSImage] = [:]
    
    private func handleNewState() {
        image = getOrMakeImage(forState: state)
        needsDisplay = true
    }
    
    
    /// Return the image corresponding with a given state, either from our cache or by making it.
    private func getOrMakeImage(forState state: State) -> NSImage {
        if let cached = imageCache[state] {
            return cached
        }
        
        let newImage = makeImage(forState: state)
        imageCache[state] = newImage
        
        return newImage
    }
    
    /// Make the image that correlates with a given state.
    private func makeImage(forState state: State) -> NSImage {
        if state == BASE_STATE {
            return BASE_IMAGE
        }
        
        guard let (hueAdjust, saturationAdjust, brightnessAdjust, contrastAdjust) = COLOR_PARAMS_MAP[state] else {
            return BASE_IMAGE
        }
        
        guard let adjustedImage = adjustImageColors(image: BASE_IMAGE, hue: hueAdjust, saturation: saturationAdjust,
                                                    brightness: brightnessAdjust, contrast: contrastAdjust) else
        {
            return BASE_IMAGE
        }
        
        return adjustedImage
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        image.draw(in: dirtyRect)
    }
    
}
