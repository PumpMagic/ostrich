//
//  JP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Jump
struct JP<T: Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == UInt16
{
    /// Condition: if present, the jump will only happen if the flag evaluates to the boolean value
    let condition: Condition?
    
    // possible jump targets: immediate extended, relative, register
    let dest: T
    
    let cycleCount = 0
    
    fileprivate func jump(_ cpu: Intel8080Like) {
        // Only jump if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            cpu.PC.write(dest.read())
        }
    }
    
    func runOn(_ cpu: Z80) {
        jump(cpu)
        
        // Never affects flag bits
    }
    
    func runOn(_ cpu: LR35902) {
        jump(cpu)
        
        // Never affects flag bits
    }
}

/// Relative jump
/// This assumes that the PC has been incremented BEFORE this instruction is executed!
/// Ie. it doesn't add two to the displacement
struct JR: Z80Instruction, LR35902Instruction
{
    /// Condition: if present, the jump will only happen if the flag evaluates to the boolean value
    let condition: Condition?
    
    let displacementMinusTwo: Int8
    
    let cycleCount = 0
    
    
    fileprivate func jump(_ cpu: Intel8080Like) {
        // Only jump if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            cpu.PC.write(Address(Int32(cpu.PC.read()) + Int32(displacementMinusTwo)))
        }
    }
    
    func runOn(_ cpu: Z80) {
        jump(cpu)
        
        // Never affects flag bits
    }
    
    func runOn(_ cpu: LR35902) {
        jump(cpu)
        
        // Never affects flag bits
    }
}
