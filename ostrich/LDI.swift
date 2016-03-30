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
        print("Running LDI")
        
        let ins1 = LD(dest: Register16Indirect8(register: z80.DE, memory: z80.memory), src: Register16Indirect8(register: z80.HL, memory: z80.memory))
        let ins2 = INC(operand: z80.DE)
        let ins3 = INC(operand: z80.HL)
        let ins4 = DEC(operand: z80.BC)
        
        ins1.runOn(z80)
        ins2.runOn(z80)
        ins3.runOn(z80)
        ins4.runOn(z80)
        
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