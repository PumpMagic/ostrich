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
        self.pulse1 = Pulse(mixer: mixer)
        self.pulse2 = Pulse(mixer: mixer)
        
        self.pulse2.volume = 0
        
        //@todo we can't use LAST or FIRST here for calculations. what can we do instead?
        self.ram = RAM(size: 0x30, fillByte: 0x00, firstAddress: 0xFF10)
    }
    
    func read(addr: Address) -> UInt8 {
        return self.ram.read(addr)
    }
    
    func write(val: UInt8, to addr: Address) {
        print("APU write! \(val) to \(addr)")
        
        self.ram.write(val, to: addr)
        
        // Update children
        //@todo there's a better way to do this
        switch addr {
        case 0xFF11:
            pulse1.duty = getValueOfBits(val, bits: 6...7)
            pulse1.length = getValueOfBits(val, bits: 0...5)
        case 0xFF12:
            pulse1.volume = getValueOfBits(val, bits: 4...7)
            //pulse1.addMode
            //pulse1.period
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
        default:
            exit(1)
        }
    }
}