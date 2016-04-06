//
//  RET.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Return: leave a function by popping the stack onto the PC
struct RET: Instruction {
    // pCL ← (sp), pCH ← (sp+1)
    
    let condition: Condition?
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        // Only return if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            z80.PC.write(z80.pop())
        }
    }
}