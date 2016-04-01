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
    // also decrements SP by two
    //      Decrement SP
    //      LD (SP), A
    //      Decrement SP
    //      LD (SP), F
    // supports 16-bit registers and indexed addresses as read sources
    let operand: T
    let cycleCount = 0 //@todo
    
    func runOn(z80: Z80) {
        print("PUSH")
        
        let val = operand.read()
        let (high, low) = getBytes(val)
        
        //@todo don't use instructions as parts of instructions! they mess with flags
        let ins1 = DEC16(operand: z80.SP)
        let ins2 = LD(dest: Register16Indirect8(register: z80.SP, memory: z80.memory), src: Immediate8(val: high))
        let ins3 = DEC16(operand: z80.SP)
        let ins4 = LD(dest: Register16Indirect8(register: z80.SP, memory: z80.memory), src: Immediate8(val: low))
        
        ins1.runOn(z80)
        ins2.runOn(z80)
        ins3.runOn(z80)
        ins4.runOn(z80)
        
        // Never affects flag bits
    }
}