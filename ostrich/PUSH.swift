//
//  PUSH.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Push: put something onto the stack, and adjust the stack pointer
struct PUSH<T: protocol<Readable, OperandType> where T.ReadType == UInt16>: Instruction {
    // (SP – 2) ← qqL, (SP – 1) ← qqH
    // supports 16-bit registers and indexed addresses as read sources
    let operand: T
    let cycleCount = 0 //@todo
    
    func runOn(z80: Z80) {
        z80.push(operand.read())
        
        // Never affects flag bits
    }
}