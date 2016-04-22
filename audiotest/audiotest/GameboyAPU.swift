//
//  GameboyAPU.swift
//  audiotest
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation
import AudioKit
import ostrichframework


func getValueOfBits(num: UInt8, bits: Range<UInt8>) -> UInt8 {
    guard let minIndex = bits.minElement() else {
        exit(1)
    }
    
    var result: UInt8 = 0
    for bitIndex in bits {
        if bitIsHigh(num, bit: bitIndex) {
            result = result + (0x01 << (bitIndex - minIndex))
        }
    }
    
    return result
}

class GameBoyAPU: Memory, HandlesWrites {
    let FIRST_ADDRESS: Address = 0xFF10
    let LAST_ADDRESS: Address = 0xFF3F
    
    let pulse1: Pulse
    let pulse2: Pulse
    
    let ram: RAM
    
    var firstAddress: Address {
        return FIRST_ADDRESS
    }
    var lastAddress: Address {
        return LAST_ADDRESS
    }
    var addressRange: Range<Address> {
        return self.firstAddress ... self.lastAddress
    }
    
    init(mixer: AKMixer) {
        self.pulse1 = Pulse(mixer: mixer, hasFrequencySweep: true, connected: true)
        self.pulse2 = Pulse(mixer: mixer, hasFrequencySweep: false, connected: true)
        
        self.pulse2.volume = 0
        
        //@todo we can't use LAST or FIRST here for calculations. what can we do instead?
        self.ram = RAM(size: 0x30, fillByte: 0x00, firstAddress: 0xFF10)
    }
    
    func read(addr: Address) -> UInt8 {
        print("APU read! \(addr.hexString)")
        return self.ram.read(addr)
    }
    
    func write(val: UInt8, to addr: Address) {
//        print("APU write! \(val.hexString) to \(addr.hexString)")
        
        self.ram.write(val, to: addr)
        
        // Update children
        //@todo there's a better way to do this
        switch addr {
            
        // 0xFF10 - 0xFF14: Pulse 1
        case 0xFF10:
            print("Write to 0xFF10! \(val)")
            pulse1.frequencySweepPeriod = getValueOfBits(val, bits: 4...6)
            pulse1.frequencySweepNegate = getValueOfBits(val, bits: 3...3)
            pulse1.frequencySweepShift = getValueOfBits(val, bits: 0...2)
            break
            
        case 0xFF11:
            pulse1.duty = getValueOfBits(val, bits: 6...7)
            pulse1.lengthCounterLoad = getValueOfBits(val, bits: 0...5)
            
        case 0xFF12:
            pulse1.volumeLoad = getValueOfBits(val, bits: 4...7)
            pulse1.envelopeAddMode = getValueOfBits(val, bits: 3...3)
            pulse1.envelopePeriod = getValueOfBits(val, bits: 0...2)
            
        case 0xFF13:
            let frequencyLow = val
            let ff14 = self.ram.read(0xFF14)
            let frequencyHigh = getValueOfBits(ff14, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
//            pulse1.frequency = frequency
            
        case 0xFF14:
            let frequencyLow = self.ram.read(0xFF13)
            let ff14 = val
            let frequencyHigh = getValueOfBits(ff14, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
            
//            print("high: \(val), low: \(frequencyLow) -> \(frequency)")
            
            pulse1.frequency = frequency
            pulse1.trigger = getValueOfBits(val, bits: 7...7)
            pulse1.lengthEnableLoad = getValueOfBits(val, bits: 6...6)
            
            
        // 0xFF15 - 0xFF19: Pulse 2
        case 0xFF15:
            // unused
            break
            
        case 0xFF16:
            pulse2.duty = getValueOfBits(val, bits: 6...7)
            pulse2.lengthCounterLoad = getValueOfBits(val, bits: 0...5)
            
        case 0xFF17:
            pulse2.volumeLoad = getValueOfBits(val, bits: 4...7)
            pulse2.envelopeAddMode = getValueOfBits(val, bits: 3...3)
            pulse2.envelopePeriod = getValueOfBits(val, bits: 0...2)
            
        case 0xFF18:
            let frequencyLow = val
            let ff19 = self.ram.read(0xFF19)
            let frequencyHigh = getValueOfBits(ff19, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
            
//            pulse2.frequency = frequency
            
        case 0xFF19:
            let frequencyLow = self.ram.read(0xFF18)
            let ff19 = val
            let frequencyHigh = getValueOfBits(ff19, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
            
            pulse2.frequency = frequency
            pulse2.trigger = getValueOfBits(val, bits: 7...7)
            pulse2.lengthEnableLoad = getValueOfBits(val, bits: 6...6)
            
        default:
            //print("Ignoring!")
            //exit(1)
            break
        }
    }
    
    
    //@todo we shouldn't rely on our caller to call this - we should have some internal timer
    var clockIndex = 0 // 0-3
    func clock256() {
        pulse1.lengthTimerFired()
        pulse2.lengthTimerFired()
        
        if clockIndex == 1 || clockIndex == 3 {
            pulse1.sweepTimerFired()
        }
        
        if clockIndex == 3 {
            pulse1.envelopeTimerFired()
            pulse2.envelopeTimerFired()
        }
        
        clockIndex += 1
        if clockIndex > 3 {
            clockIndex = 0
        }
    }
}

protocol HexStringConvertible {
    /// Representation of this number as 0x%0#X
    var hexString: String { get }
}

extension UInt8: HexStringConvertible {
    /// Representation of this number as 0x%02X
    var hexString: String { return String(format: "0x%02X", self) }
}

extension UInt16: HexStringConvertible {
    /// Representation of this number as 0x%04X
    var hexString: String { return String(format: "0x%04X", self) }
}