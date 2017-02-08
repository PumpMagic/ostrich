//
//  GBDPad.swift
//  gbsplayer
//
//  Created by Owner on 2/3/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa


class GBDPad: NSView {
    enum Direction {
        case Neutral
        case Up
        case Down
        case Left
        case Right
    }
    
    private let images: [Direction : NSImage?] = [.Neutral: Bundle.main.image(forResource: "dpad-neutral.png"),
                                                 .Up: Bundle.main.image(forResource: "dpad-up.png"),
                                                 .Down: Bundle.main.image(forResource: "dpad-down.png"),
                                                 .Left: Bundle.main.image(forResource: "dpad-left.png"),
                                                 .Right: Bundle.main.image(forResource: "dpad-right.png")]
    private var currentImage: NSImage? = nil
    private var eventHandler: ((Direction) -> Void)? = nil
    
    
    /// What does the button call when it's been pressed?
    func setEventHandler(callback: @escaping (Direction) -> Void) {
        self.eventHandler = callback
    }
    
    /// Update our image.
    private func updateImage(direction: Direction) {
        if let image = images[direction] {
            currentImage = image
            self.needsDisplay = true
        }
        
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
    
    
    /// Take in a point inside the window we're in, and return whether or not that point
    /// is part of us.
    private func directionForPoint(point: NSPoint) -> Direction {
        // Regions:
        // Top: 1/3 <= x <= 2/3, y <= 1/3
        // Bottom: 1/3 <= x <= 2/3, y >= 2/3
        // Left: x <= 1/3, 1/3 <= y <= 2/3
        // Right: x >= 2/3, 1/3 <= y <= 2/3
        
        let relativeToSelf = self.convert(point, from: nil)
        
        if relativeToSelf.x >= (bounds.width / 3) && relativeToSelf.x <= (bounds.width * 2 / 3) {
            if relativeToSelf.y >= (bounds.height * 2 / 3) && relativeToSelf.y <= bounds.height {
                return .Up
            }
            if relativeToSelf.y >= 0 && relativeToSelf.y <= (bounds.height / 3) {
                return .Down
            }
        }
        if relativeToSelf.y >= (bounds.height / 3) && relativeToSelf.y <= (bounds.height * 2 / 3) {
            if relativeToSelf.x >= 0 && relativeToSelf.x <= (bounds.width / 3) {
                return .Left
            }
            if relativeToSelf.x >= (bounds.width * 2 / 3) && relativeToSelf.x <= bounds.width {
                return .Right
            }
        }
        
        return .Neutral
    }
    
    override func mouseDown(with event: NSEvent) {
        updateImage(direction: directionForPoint(point: event.locationInWindow))
    }
    
    override func mouseDragged(with event: NSEvent) {
        updateImage(direction: directionForPoint(point: event.locationInWindow))
    }
    
    override func mouseUp(with event: NSEvent) {
        updateImage(direction: .Neutral)
        
        /// If the mouse was released while in our view, treat the event as a press of us
        if self.contains(point: event.locationInWindow) {
            eventHandler?(directionForPoint(point: event.locationInWindow))
        }
    }
    
    
    override func viewDidMoveToWindow() {
        updateImage(direction: .Neutral)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        currentImage?.draw(in: dirtyRect)
    }
    
}
