//
//  PulseWaveView.swift
//  gbsplayer
//
//  Created by Owner on 1/24/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa
import ostrich

//@todo this needs serious cleanup:
// 1. it shouldn't need to peer so deeply into the pulse channel, or at least shouldn't need to use redundant conversion functions
// 2. its computations should be performed in another thread, so that only drawing is done in draw()
// 3. code cleanliness is poor
// 4. magic numbers
class PulseWaveView: NSView {

    var amplitude = 1.0 // [0.0, 1.0]
    var frequency = 200.0 // Hz
    var duty = 0.5 // [0.0, 1.0]
    
    var channel: Pulse? = nil
    
    // if one second is 200 pixels, then...
    // 10 Hz = vert. every 10 px
    // 20 Hz = vert. every 5 px
    
    let PIXELS_PER_SECOND = 40000.0
    
    
    func drawFlatLine() {
        let startPoint = CGPoint(x: bounds.minX, y: bounds.midY)
        let endPoint = CGPoint(x: bounds.maxX, y: bounds.midY)
        
        NSColor.black.setStroke()
        let path = NSBezierPath()
        path.move(to: startPoint)
        path.line(to: endPoint)
        path.stroke()
        path.close()
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let channel = self.channel else { return }
        
        amplitude = Double(channel.volume) / 15.0
        
        if amplitude == 0.0 {
            drawFlatLine()
            return
        }
        
        // The frequency of the output pulse wave is (4194304 / 8 / (2048-frequency)), stolen from Pulse class...
        //@todo remove redundancy
        frequency = 4194304.0 / 8.0 / Double(2048 - channel.frequency)
        
        //@todo remove potential redundancy
        switch channel.duty {
        case 0b00:
            duty = 0.125
        case 0b01:
            duty = 0.25
        case 0b10:
            duty = 0.50
        case 0b11:
            duty = 0.75
        default:
            duty = 0.0
        }
        
        let waveMinX = bounds.minX
        let waveMaxX = bounds.maxX
        
        let waveBaseY = bounds.midY
        let waveHeight = CGFloat(50 * amplitude)
        let waveMinY = waveBaseY - (waveHeight/2)
        let waveMaxY = waveBaseY + (waveHeight/2)
        
        
        
        var x = CGFloat(waveMinX)
        var y = CGFloat(waveMaxY)
        
        let path = NSBezierPath()
        let startingPoint = CGPoint(x: x, y: y)
        NSColor.black.setStroke()
        path.move(to: startingPoint)
        
        while x < waveMaxX {
            var done = false
            
            // Start just before high time
            let xHigh = CGFloat(PIXELS_PER_SECOND / frequency * duty)
            x += xHigh
            if x > waveMaxX {
                x = waveMaxX
                done = true
            }
            let highJump = CGPoint(x: x, y: y)
            path.line(to: highJump)
            
            if done { break }
            
            // Just ended high time, now go down
            //@todo don't go down if duty if 100%
            
            y = waveMinY
            let downJump = CGPoint(x: x, y: y)
            path.line(to: downJump)
            
            // Just went down, now go low
            
            let xLow = CGFloat(PIXELS_PER_SECOND / frequency * (1-duty))
            x += xLow
            if x > waveMaxX {
                x = waveMaxX
                done = true
            }
            let lowJump = CGPoint(x: x, y: y)
            path.line(to: lowJump)
            
            if done { break }
            
            // Just went low, now go up
            
            y = waveMaxY
            let upJump = CGPoint(x: x, y: y)
            path.line(to: upJump)
        }
        
        path.stroke()
        path.close()
    }
    
}
