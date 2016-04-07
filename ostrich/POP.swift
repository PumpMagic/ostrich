//
//  POP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Pop: pop the top of the stack onto something, and adjust the stack pointer
struct POP<T: protocol<Writeable, OperandType> where T.WriteType == UInt16>: Z80Instruction, LR35902Instruction
{
    // qqH ← (SP+1), qqL ← (SP)
    // also increments SP by two
    // supports 16-bit registers and indexed addresses as write sources
    let operand: T
    let cycleCount = 0
    
    func runOn(cpu: Z80) {
        operand.write(cpu.pop())
        
        // Never affects flag bits
    }
    
    func runOn(cpu: LR35902) {
        operand.write(cpu.pop())
        
        // Never affects flag bits
    }
}