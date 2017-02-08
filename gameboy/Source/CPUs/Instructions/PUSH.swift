//
//  PUSH.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Push: put something onto the stack, and adjust the stack pointer
struct PUSH<T: Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == UInt16
{
    // (SP – 2) ← qqL, (SP – 1) ← qqH
    // supports 16-bit registers and indexed addresses as read sources
    let operand: T
    let cycleCount = 0
    
    fileprivate func runCommon(_ cpu: Intel8080Like) {
        cpu.push(operand.read())
        
        // Never affects flag bits
    }
    
    func runOn(_ cpu: Z80) {
        runCommon(cpu)
    }
    
    func runOn(_ cpu: LR35902) {
        runCommon(cpu)
    }
}
