//
//  GameboyAPU.swift
//  audiotest
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation
import AudioKit


/// Get the value of a certain range of bits in a number, as though the bits were their own value
/// whose LSB is the lowest bit in the range and represents 1
/// For example, getValueOfBits(0b10101010, 2...4) selects bits 2-4 (010) and returns 2
public func getValueOfBits(_ num: UInt8, bits: CountableClosedRange<UInt8>) -> UInt8 {
    guard let minIndex = bits.min() else {
        exit(1)
    }
    
    var result: UInt8 = 0
    for bitIndex in bits {
        let relativeIndex = bitIndex - minIndex
        if bitIsHigh(num, bit: bitIndex) {
            result = result + (0x01 << relativeIndex)
        }
    }
    
    return result
}

public class GameBoyAPU: Memory, HandlesWrites {
    let FIRST_ADDRESS: Address = 0xFF10
    let LAST_ADDRESS: Address = 0xFF3F
    
    public let pulse1: Pulse
    public let pulse2: Pulse
    
    let ram: RAM
    
    public var firstAddress: Address {
        return FIRST_ADDRESS
    }
    public var lastAddress: Address {
        return LAST_ADDRESS
    }
    public var addressRange: CountableClosedRange<Address> {
        return Address(self.firstAddress) ... Address(self.lastAddress)
    }
    
    init(mixer: AKMixer) {
        self.pulse1 = Pulse(mixer: mixer, hasFrequencySweep: true, connected: true)
        self.pulse2 = Pulse(mixer: mixer, hasFrequencySweep: false, connected: true)
        self.pulse1.initializeCounterCallbacks()
        self.pulse2.initializeCounterCallbacks()
        
        //@todo we can't use LAST or FIRST here for calculations. what can we do instead?
        self.ram = RAM(size: 0x30, fillByte: 0x00, firstAddress: 0xFF10)
    }
    
    public func read(_ addr: Address) -> UInt8 {
//        print("APU read! \(addr.hexString)")
        return self.ram.read(addr)
    }
    
    public func write(_ val: UInt8, to addr: Address) {
//        print("APU write! \(val.hexString) to \(addr.hexString)")
        
        self.ram.write(val, to: addr)
        
        // Update children
        //@todo there's a better way to do this
        switch addr {
            
        // 0xFF10 - 0xFF14: Pulse 1
        case 0xFF10:
            pulse1.frequencySweepPeriod = getValueOfBits(val, bits: 4...6)
            pulse1.frequencySweepNegate = getValueOfBits(val, bits: 3...3)
            pulse1.frequencySweepShift = getValueOfBits(val, bits: 0...2)
            break
            
        case 0xFF11:
            pulse1.duty = getValueOfBits(val, bits: 6...7)
            pulse1.lengthCounterLoad = getValueOfBits(val, bits: 0...5)
            
        case 0xFF12:
            pulse1.startingVolume = getValueOfBits(val, bits: 4...7)
            pulse1.envelopeAddMode = getValueOfBits(val, bits: 3...3)
            pulse1.envelopePeriod = getValueOfBits(val, bits: 0...2)
            
        case 0xFF13:
            let frequencyLow = val
            let ff14 = self.ram.read(0xFF14)
            let frequencyHigh = getValueOfBits(ff14, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
            
            pulse1.frequency = frequency
            
        case 0xFF14:
            let frequencyLow = self.ram.read(0xFF13)
            let ff14 = val
            let frequencyHigh = getValueOfBits(ff14, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
            
            pulse1.frequency = frequency
            pulse1.trigger = getValueOfBits(val, bits: 7...7)
            pulse1.lengthEnable = getValueOfBits(val, bits: 6...6)
            
            
        // 0xFF15 - 0xFF19: Pulse 2
        case 0xFF15:
            // unused
            break
            
        case 0xFF16:
            pulse2.duty = getValueOfBits(val, bits: 6...7)
            pulse2.lengthCounterLoad = getValueOfBits(val, bits: 0...5)
            
        case 0xFF17:
            pulse2.startingVolume = getValueOfBits(val, bits: 4...7)
            pulse2.envelopeAddMode = getValueOfBits(val, bits: 3...3)
            pulse2.envelopePeriod = getValueOfBits(val, bits: 0...2)
            
        case 0xFF18:
            let frequencyLow = val
            let ff19 = self.ram.read(0xFF19)
            let frequencyHigh = getValueOfBits(ff19, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
            
            pulse2.frequency = frequency
            
        case 0xFF19:
            let frequencyLow = self.ram.read(0xFF18)
            let ff19 = val
            let frequencyHigh = getValueOfBits(ff19, bits: 0...2)
            let frequency = make16(high: frequencyHigh, low: frequencyLow)
            
            pulse2.frequency = frequency
            pulse2.trigger = getValueOfBits(val, bits: 7...7)
            pulse2.lengthEnable = getValueOfBits(val, bits: 6...6)
            
//        case 0xFF24, 0xFF25, 0xFF26:
            // Power control / status
//            print("Write to power control! \(addr.hexString) <- \(val.hexString)")
//            exit(1)
            
        default:
            //print("Ignoring!")
            //exit(1)
            break
        }
    }
    
    
    var clockIndex = 0 // 0-3
    public func clock256() {
        pulse1.clock256()
        pulse2.clock256()
        
        // 128Hz - every other 256Hz clock
        if clockIndex == 1 || clockIndex == 3 {
            pulse1.sweepTimerFired()
        }
        
        // 64Hz - every fourth 256Hz clock
        if clockIndex == 3 {
            pulse1.clock64()
            pulse2.clock64()
        }
        
        clockIndex += 1
        if clockIndex > 3 {
            clockIndex = 0
        }
    }
}
