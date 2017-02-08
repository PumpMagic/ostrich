//
//  CALL.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/1/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Call: call a function by pushing the PC onto the stack and jumping
struct CALL<T: Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == UInt16
{
    // (SP – 1) ← PCH, (SP – 2) ← PCL, PC ← nn
    
    let condition: Condition?
    let dest: T
    
    let cycleCount = 0
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) {
        // Only call if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            cpu.push(cpu.PC.read())
            cpu.PC.write(dest.read())
        }
    }
    
    func runOn(_ cpu: Z80) {
        runCommon(cpu)
    }
    
    func runOn(_ cpu: LR35902) {
        runCommon(cpu)
    }
}
