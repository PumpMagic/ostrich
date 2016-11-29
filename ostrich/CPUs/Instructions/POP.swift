//
//  POP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Pop: pop the top of the stack onto something, and adjust the stack pointer
struct POP<T: Writeable & OperandType>: Z80Instruction, LR35902Instruction where T.WriteType == UInt16
{
    // qqH ← (SP+1), qqL ← (SP)
    // also increments SP by two
    // supports 16-bit registers and indexed addresses as write sources
    let operand: T
    let cycleCount = 0
    
    func runOn(_ cpu: Z80) {
        operand.write(cpu.pop())
        
        // Never affects flag bits
    }
    
    func runOn(_ cpu: LR35902) {
        operand.write(cpu.pop())
        
        // Never affects flag bits
    }
}
