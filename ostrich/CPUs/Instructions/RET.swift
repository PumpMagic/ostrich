//
//  RET.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Return: leave a function by popping the stack onto the PC
struct RET: Z80Instruction, LR35902Instruction {
    // pCL ← (sp), pCH ← (sp+1)
    
    let condition: Condition?
    
    let cycleCount = 0
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) {
        // Only call if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            cpu.PC.write(cpu.pop())
        }
    }
    
    func runOn(_ cpu: Z80) {
        runCommon(cpu)
    }
    
    func runOn(_ cpu: LR35902) {
        runCommon(cpu)
    }
}


/// Return then enable interrupts
struct RETI: LR35902Instruction {
    // pCL ← (sp), pCH ← (sp+1)
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: LR35902) {
        cpu.PC.write(cpu.pop())
        cpu.IFF1 = .enabled
        cpu.IFF2 = .enabled
    }
}
