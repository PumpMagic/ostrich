//
//  RET.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Return: leave a function by populating the PC with the top of the stack
struct RET: Instruction {
    // pCL ← (sp), pCH ← (sp+1)
    
    let condition: Condition?
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print(String(format: "Running JP. SP before: 0x%04X", z80.SP.read()))
        print(String(format: "\tPC before: 0x%04X", z80.PC.read()))
        
        let top_of_stack = Memory16Translator(addr: z80.SP.read(), memory: z80.memory).read()
        
        z80.PC.write(top_of_stack)
        z80.SP.write(z80.SP.read() + 2)
        
        print(String(format: "\tSP after: 0x%04X", z80.SP.read()))
        print(String(format: "\tPC after: 0x%04X", z80.PC.read()))
    }
}