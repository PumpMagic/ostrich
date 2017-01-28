//
//  GBRoundButton.swift
//  gbsplayer
//
//  Created by Owner on 1/26/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


protocol CustomButtonDelegate {
    func handleCustomButtonPress(sender: NSView)
}


let UNPRESSED_FILENAME = "gb-button-unpressed.png"
let PRESSED_FILENAME = "gb-button-pressed.png"
let UNPRESSED_IMAGE: NSImage! = Bundle.main.image(forResource: UNPRESSED_FILENAME)
let PRESSED_IMAGE: NSImage! = Bundle.main.image(forResource: PRESSED_FILENAME)


class GBRoundButton: NSView {
    var currentImage: NSImage = UNPRESSED_IMAGE
    var delegate: CustomButtonDelegate? = nil
    
    /// Update our image
    func updateImage(selected: Bool) {
        if selected {
            self.currentImage = PRESSED_IMAGE
        } else {
            self.currentImage = UNPRESSED_IMAGE
        }
        
        self.needsDisplay = true
    }
    
    /// Take in a point inside the window we're in, and return whether or not that point
    /// is part of us
    func contains(point: NSPoint) -> Bool {
        let relativeToSelf = self.convert(point, from: nil)
        
        if relativeToSelf.x >= 0 && relativeToSelf.x < self.bounds.width &&
            relativeToSelf.y >= 0 && relativeToSelf.y < self.bounds.height
        {
            return true
        }
        
        return false
    }
    
    override func mouseDown(with event: NSEvent) {
        updateImage(selected: true)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let cursorIsInUs = self.contains(point: event.locationInWindow)
        updateImage(selected: cursorIsInUs)
    }
    
    override func mouseUp(with event: NSEvent) {
        updateImage(selected: false)
        
        if let delegate = self.delegate {
            let cursorIsInUs = self.contains(point: event.locationInWindow)
            if cursorIsInUs {
                delegate.handleCustomButtonPress(sender: self)
            }
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        currentImage.draw(in: dirtyRect)
    }
    
}
