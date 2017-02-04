//
//  PulseWaveView.swift
//  gbsplayer
//
//  Created by Owner on 1/24/17.
//  Copyright © 2017 conwarez. All rights reserved.
//

import Cocoa
import ostrich

// Some configuration constants
fileprivate let PIXELS_PER_SECOND_SCALE_FACTOR = 50.0
fileprivate let LINE_WIDTH: CGFloat = 1.5
fileprivate let CONNECTED_STROKE_COLOR = GAMEBOY_PALLETTE_11
fileprivate let DISCONNECTED_STROKE_COLOR = GAMEBOY_PALLETTE_01


/// A viewable representation of a pulse wave channel. Updates only when needsDisplay is set by someone else.
class PulseWaveView: NSView {
    /// Channel we're drawing
    var channel: Pulse? = nil
    
    var strokeColor: NSColor {
        guard let channel = self.channel else {
            return DISCONNECTED_STROKE_COLOR
        }
        
        if channel.isConnected() {
            return CONNECTED_STROKE_COLOR
        } else {
            return DISCONNECTED_STROKE_COLOR
        }
    }
    
    
    /// Draw a flat line as the waveform
    private func drawFlatLine(at y: CGFloat) {
        let startPoint = CGPoint(x: bounds.minX, y: y)
        let endPoint = CGPoint(x: bounds.maxX, y: y)
        
        strokeColor.set()
        let path = NSBezierPath()
        path.lineWidth = LINE_WIDTH
        path.move(to: startPoint)
        path.line(to: endPoint)
        path.stroke()
        path.close()
    }
    
    private func drawRectangle(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let path = NSBezierPath(rect: NSRect(x: x, y: y, width: width, height: height))
        strokeColor.set()
        path.fill()
    }
    
    /// Draw the pulse wave.
    /// Amplitude should be [0.0, 1.0]; frequency should be in Hz; duty should be [0.0, 1.0].
    private func drawWaveform(amplitude: Double, frequency: Double, duty: Double) {
        if amplitude == 0.0 || duty == 0.0 {
            drawFlatLine(at: bounds.minY)
            return
        }
        
        let waveMinX = bounds.minX
        let waveMaxX = bounds.maxX
        
        let waveHeight = floor(bounds.height * CGFloat(amplitude))
        let waveMinY = bounds.minY
        let waveMaxY = bounds.minY + waveHeight - 1
        
        let pixelsPerSecond = Double(bounds.width) * PIXELS_PER_SECOND_SCALE_FACTOR
        
        if frequency > (pixelsPerSecond/2) {
            // The waveform is so dense that our output, rendered carefully, would just be a solid block.
            // Rather than spending the resources, just output a solid block directly
            drawRectangle(x: waveMinX, y: waveMinY, width: (waveMaxX-waveMinX), height: (waveMaxY-waveMinY))
            return
        }
        
        var x = CGFloat(waveMinX)
        var y = CGFloat(waveMinY)
        
        let path = NSBezierPath()
        path.lineWidth = LINE_WIDTH
        let startingPoint = CGPoint(x: x, y: y)
        strokeColor.set()
        path.move(to: startingPoint)
        
        // Draw half-periods of the pulse wave until we reach the edge of our view
        while x < waveMaxX {
            // Draw a horizontal edge
            let maxNextX: CGFloat
            if y == waveMinY {
                // bottom edge
                maxNextX = x + CGFloat(pixelsPerSecond / frequency * (1-duty))
            } else {
                // top edge
                maxNextX = x + CGFloat(pixelsPerSecond / frequency * (duty))
            }
            
            let nextX = min(waveMaxX, maxNextX)
            path.line(to: CGPoint(x: nextX, y: y))
            x = nextX
            
            if x < waveMaxX {
                // Draw a vertical edge
                let nextY: CGFloat
                if y == waveMinY {
                    // bottom-top transition
                    nextY = waveMaxY
                } else {
                    // top-bottom transition
                    nextY = waveMinY
                }
                
                path.line(to: CGPoint(x: x, y: nextY))
                y = nextY
            }
        }
        
        // Stroke our curve
        path.stroke()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let channel = self.channel else {
            // We haven't been configured with a channel yet
            drawFlatLine(at: bounds.minY)
            return
        }
        
        let amplitude = channel.getMusicalAmplitude()
        let frequency = channel.getMusicalFrequency()
        let duty = channel.getDutyCycle()
        drawWaveform(amplitude: amplitude, frequency: frequency, duty: duty)
    }
    
}
