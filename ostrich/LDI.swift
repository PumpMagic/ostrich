//
//  LDI.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// A special load-increment-increment-decrement, used to copy arrays or something
//@warn the Z80's "LDI" is completely different from the LR35902's "LDI". this is the Z80's
struct LDI: Z80Instruction {
    let cycleCount = 0
    
    func runOn(cpu: Z80) {
        cpu.DE.asIndirectInto(cpu.bus).write(cpu.HL.asIndirectInto(cpu.bus).read())
        incAndStore(cpu.DE)
        incAndStore(cpu.HL)
        decAndStore(cpu.BC)
        
        modifyFlags(cpu)
    }
    
    func modifyFlags(cpu: Z80) {
        // S is not affected.
        // Z is not affected.
        // H is reset.
        // P/V is set if BC – 1 ≠ 0; otherwise, it is reset.
        // N is reset.
        // C is not affected.
        
        let newBC = cpu.BC.read()
        
        cpu.HF.write(false)
        cpu.PVF.write(newBC != 0x00)
        cpu.NF.write(false)
    }
}