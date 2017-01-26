//
//  GBRoundButton.swift
//  gbsplayer
//
//  Created by Owner on 1/26/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa

class GBRoundButton: NSButton {

    var color: NSColor = NSColor.red
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        self.color = NSColor.green
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        let path = NSBezierPath(ovalIn: dirtyRect)
        self.color.setFill()
        path.fill()
    }
    
}
