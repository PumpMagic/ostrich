//
//  LDI.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// A special load-increment-increment-decrement, used to copy arrays or something
///@warn this uses z80.memory
struct LDI: Instruction {
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        z80.DE.asIndirectInto(z80.memory).write(z80.HL.asIndirectInto(z80.memory).read())
        z80.DE.write(z80.DE.read() + 1)
        z80.HL.write(z80.HL.read() + 1)
        z80.BC.write(z80.BC.read() - 1)
        
        self.modifyFlags(z80)
    }
    
    func modifyFlags(z80: Z80) {
        // S is not affected.
        // Z is not affected.
        // H is reset.
        // P/V is set if BC – 1 ≠ 0; otherwise, it is reset.
        // N is reset.
        // C is not affected.
        
        let newBC = z80.BC.read()
        
        z80.HF.write(false)
        z80.PVF.write(newBC != 0x00)
        z80.NF.write(false)
    }
}