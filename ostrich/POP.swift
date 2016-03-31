//
//  POP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Pop: pop the top of the stack onto something, and adjust the stack pointer
struct POP<T: protocol<Writeable, OperandType> where T.WriteType == UInt16>: Instruction {
    // qqH ← (SP+1), qqL ← (SP)
    // also increments SP by two
    // supports 16-bit registers and indexed addresses as write sources
    let operand: T
    let cycleCount = 0 //@todo
    
    func runOn(z80: Z80) {
        print("POP")
        
        let val = z80.memory.read16(z80.SP.read())
        
        //@todo don't use instructions as parts of instructions! they mess with flags
        let ins = LD(dest: operand, src: Immediate16(val: val))
        ins.runOn(z80)
        
        // Never affects flag bits
    }
}