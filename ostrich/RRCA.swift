//
//  RRCA.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/30/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Right rotate with carry A
struct RRCA: Instruction {
    //@warn the Z80 manual's example has something that doesn't look like a proper right rotate
    // it's probably an error in the manual, so this instruction implements an actual rotate...
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        let oldA = z80.A.read()
        
        print(String(format: "Running RRCA. A before: 0x%02X", oldA))
        
        z80.A.write(rotateRight(oldA))
        modifyFlags(z80, oldValue: oldA)
        
        print(String(format: "\tA after: 0x%04X", z80.A.read()))
    }
    
    func modifyFlags(z80: Z80, oldValue: UInt8) {
        // S is not affected.
        // Z is not affected.
        // H is reset.
        // P/V is not affected.
        // N is reset.
        // C is data from bit 0 of Accumulator.
        
        z80.HF.write(false)
        z80.NF.write(false)
        z80.CF.write(bitIsHigh(oldValue, bit: 0))
    }
}