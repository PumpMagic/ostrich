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
class PulseWaveView: NSView {

    var amplitude = 1.0 // [0.0, 1.0]
    var frequency = 200.0 // Hz
    var duty = 0.5 // [0.0, 1.0]
    
    var channel: Pulse? = nil
    
    // if one second is 200 pixels, then...
    // 10 Hz = vert. every 10 px
    // 20 Hz = vert. every 5 px
    
    // typ. range is probably 100 - 3000 Hz, let's just try that
    // let's just try accommodating max of 20,000 Hz
    // so if one second is 40,000 px, then 20,000 Hz is a 2px / period
    // And 10,000 Hz is 4px / period
    // Yeah let's try that
    let PIXELS_PER_SECOND = 40000.0
    
    override func draw(_ dirtyRect: NSRect) {
        guard let channel = self.channel else { return }
        
        super.draw(dirtyRect)
        
        amplitude = Double(channel.volume) / 15.0 + 0.01
        
        //The frequency of the output pulse wave is (4194304 / 8 / frequency), since the wavetable is
        frequency = 4194304.0 / 8.0 / Double(2048 - channel.frequency)
        
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

        // Drawing code here.
//        Swift.print("Draw called \(amplitude) \(frequency) \(duty)")
        
        let minX = bounds.minX + 1
        let maxX = bounds.maxX - 1
        
        let minY = bounds.minY + 1
        //let maxY = bounds.maxY - 1
        let maxY = minY + CGFloat(100 * amplitude)
        
        
        
        var x = CGFloat(minX)
        var y = CGFloat(maxY)
        
        let path = NSBezierPath()
        let startingPoint = CGPoint(x: x, y: y)
        NSColor.black.setStroke()
        path.move(to: startingPoint)
        
        while x < maxX {
            var done = false
            
            // Start just before high time
            let xHigh = CGFloat(PIXELS_PER_SECOND / frequency * duty)
            x += xHigh
            if x > maxX {
                x = maxX
                done = true
            }
            let highJump = CGPoint(x: x, y: y)
            path.line(to: highJump)
            
            if done { break }
            
            // Just ended high time, now go down
            //@todo don't go down if duty if 100%
            
            y = minY
            let downJump = CGPoint(x: x, y: y)
            path.line(to: downJump)
            
            // Just went down, now go low
            
            let xLow = CGFloat(PIXELS_PER_SECOND / frequency * (1-duty))
            x += xLow
            if x > maxX {
                x = maxX
                done = true
            }
            let lowJump = CGPoint(x: x, y: y)
            path.line(to: lowJump)
            
            if done { break }
            
            // Just went low, now go up
            
            y = maxY
            let upJump = CGPoint(x: x, y: y)
            path.line(to: upJump)
        }
        
        path.stroke()
        path.close()
    }
    
}
