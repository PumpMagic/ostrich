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
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        operand.write(z80.pop())
        
        // Never affects flag bits
    }
}