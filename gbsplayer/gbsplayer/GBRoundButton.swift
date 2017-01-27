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

let UNSELECTED_COLOR = NSColor(red: 179/255, green: 25/255, blue: 97/255, alpha: 1.0)
let SELECTED_COLOR = NSColor(red: 127/255, green: 9/255, blue: 69/255, alpha: 1.0)

class GBRoundButton: NSView {
    var color: NSColor = UNSELECTED_COLOR
    var delegate: CustomButtonDelegate? = nil
    
    /// Update our color
    func updateColor(selected: Bool) {
        if selected {
            self.color = SELECTED_COLOR
        } else {
            self.color = UNSELECTED_COLOR
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
        updateColor(selected: true)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let cursorIsInUs = self.contains(point: event.locationInWindow)
        updateColor(selected: cursorIsInUs)
    }
    
    override func mouseUp(with event: NSEvent) {
        updateColor(selected: false)
        
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
        let path = NSBezierPath(ovalIn: dirtyRect)
        self.color.setFill()
        path.fill()
    }
    
}
