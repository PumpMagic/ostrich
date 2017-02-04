//
//  CustomButton.swift
//  gbsplayer
//
//  Created by Owner on 2/3/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa

/// Something that can capture user events for processing by a delegate.
protocol GeneratesUIEvents {
    func setEventHandler(callback: @escaping (NSView) -> Void)
}

protocol Pushable {
    func getPushedImage() -> NSImage
    func getUnpushedImage() -> NSImage
    
    func onMouseDown()
}


/// A pressable button whose appearance mimics that of a Game Boy Classic's.
/// Dispatches button press events to delegate registered through GeneratesUIEvents's function, if any.
class CustomButton: NSView, GeneratesUIEvents {
    @IBInspectable var unpushedImage: NSImage? = nil
    @IBInspectable var pushedImage: NSImage? = nil
    private var currentImage: NSImage? = nil
    
    private var eventHandler: ((NSView) -> Void)? = nil
    
    /// What does the button call when it's been pressed?
    func setEventHandler(callback: @escaping (NSView) -> Void) {
        self.eventHandler = callback
    }
    
    /// Update our image.
    private func updateImage(selected: Bool) {
        if selected {
            currentImage = pushedImage
        } else {
            currentImage = unpushedImage
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
            eventHandler?(self)
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
        currentImage?.draw(in: dirtyRect)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateImage(selected: false)
    }
}
