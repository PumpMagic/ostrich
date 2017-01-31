//
//  GBRoundButton.swift
//  gbsplayer
//
//  Created by Owner on 1/26/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


/// Something that can capture user events for processing by a delegate.
protocol GeneratesUIEvents {
    func setEventHandler(callback: @escaping (NSView) -> Void)
}


// Some configuration constants
fileprivate let UNPRESSED_FILENAME = "gb-button-unpressed.png"
fileprivate let PRESSED_FILENAME = "gb-button-pressed.png"
fileprivate let UNPRESSED_IMAGE: NSImage! = Bundle.main.image(forResource: UNPRESSED_FILENAME)
fileprivate let PRESSED_IMAGE: NSImage! = Bundle.main.image(forResource: PRESSED_FILENAME)


/// A pressable button whose appearance mimics that of a Game Boy Classic's.
/// Dispatches button press events to delegate registered through GeneratesUIEvents's function, if any.
class GBRoundButton: NSView, GeneratesUIEvents {
    private var currentImage: NSImage = UNPRESSED_IMAGE
    private var pushHandler: ((NSView) -> Void)? = nil
    
    
    /// Set the event handler: what does the button call when it's been pressed?
    func setEventHandler(callback: @escaping (NSView) -> Void) {
        self.pushHandler = callback
    }
    
    /// Update our image.
    private func updateImage(selected: Bool) {
        if selected {
            self.currentImage = PRESSED_IMAGE
        } else {
            self.currentImage = UNPRESSED_IMAGE
        }
        
        self.needsDisplay = true
    }
    
    /// Take in a point inside the window we're in, and return whether or not that point
    /// is part of us.
    private func contains(point: NSPoint) -> Bool {
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
        
        /// If the mouse was released while in our view, treat the event as a press of us
        if self.contains(point: event.locationInWindow) {
            pushHandler?(self)
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
