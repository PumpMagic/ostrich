//
//  PulseWaveView.swift
//  gbsplayer
//
//  Created by Owner on 1/24/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa
import ostrich


let PIXELS_PER_SECOND = 10000.0

//@todo magic numbers
class PulseWaveView: NSView {

    var amplitude = 1.0 // [0.0, 1.0]
    var frequency = 200.0 // Hz
    var duty = 0.5 // (0.0, 1.0)
    
    var channel: Pulse? = nil
    
    
    /// Update our local knowledge of the properties of the channel we're displaying
    func updateProperties() {
        guard let channel = self.channel else { return }
        
        amplitude = channel.getMusicalAmplitude()
        frequency = channel.getMusicalFrequency()
        duty = channel.getDutyCycle()
    }
    
    /// Draw a flat line as the waveform
    func drawFlatLine() {
        let startPoint = CGPoint(x: bounds.minX, y: bounds.minY)
        let endPoint = CGPoint(x: bounds.maxX, y: bounds.minY)
        
        NSColor.black.setStroke()
        let path = NSBezierPath()
        path.move(to: startPoint)
        path.line(to: endPoint)
        path.stroke()
        path.close()
    }
    
    /// Draw the pulse wave
    func drawWaveform() {
        if amplitude == 0.0 {
            drawFlatLine()
            return
        }
        
        let waveMinX = bounds.minX
        let waveMaxX = bounds.maxX
        
        let waveHeight = floor(bounds.height * CGFloat(amplitude))
//        let waveMinY = floor(bounds.midY - (waveHeight/2))
//        let waveMaxY = floor(bounds.midY + (waveHeight/2))
        let waveMinY = bounds.minY
        let waveMaxY = bounds.minY + (bounds.height * CGFloat(amplitude))
        
        if waveMinY < bounds.minY {
            Swift.print("Amplitude: \(amplitude) wave height: \(waveHeight) wave min Y: \(waveMinY) wave max Y: \(waveMaxY) bounds min Y: \(bounds.minY) bounds max Y: \(bounds.maxY) bounds mid Y: \(bounds.midY)")
        }
        
        var x = CGFloat(waveMinX)
        var y = CGFloat(waveMinY)
        
        let path = NSBezierPath()
        let startingPoint = CGPoint(x: x, y: y)
        NSColor.black.setStroke()
        path.move(to: startingPoint)
        
        // Draw half-periods of the pulse wave until we reach the edge of our view
        while x < waveMaxX {
            // Horizontal edge
            let maxNextX: CGFloat
            if y == waveMinY {
                // bottom edge
                maxNextX = x + CGFloat(PIXELS_PER_SECOND / frequency * (1-duty))
            } else {
                // top edge
                maxNextX = x + CGFloat(PIXELS_PER_SECOND / frequency * (duty))
            }
            
            let nextX = min(waveMaxX, maxNextX)
            path.line(to: CGPoint(x: nextX, y: y))
            x = nextX
            
            if x < waveMaxX {
                // Vertical edge
                let nextY: CGFloat
                if y == waveMinY {
                    nextY = waveMaxY
                } else {
                    nextY = waveMinY
                }
                
                path.line(to: CGPoint(x: x, y: nextY))
                y = nextY
            }
        }
        
        path.stroke()
        path.close()
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        updateProperties()
        drawWaveform()
    }
    
}
