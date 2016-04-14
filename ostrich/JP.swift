//
//  JP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Jump
struct JP<T: protocol<Readable, OperandType> where T.ReadType == UInt16>: Z80Instruction, LR35902Instruction
{
    /// Condition: if present, the jump will only happen if the flag evaluates to the boolean value
    let condition: Condition?
    
    // possible jump targets: immediate extended, relative, register
    let dest: T
    
    let cycleCount = 0 //@todo
    
    private func jump(cpu: Intel8080Like) {
        // Only jump if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            cpu.PC.write(dest.read())
        }
    }
    
    func runOn(cpu: Z80) {
        jump(cpu)
        
        // Never affects flag bits
    }
    
    func runOn(cpu: LR35902) {
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
    
    
    private func jump(cpu: Intel8080Like) {
        // Only jump if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            cpu.PC.write(Address(Int32(cpu.PC.read()) + Int32(displacementMinusTwo)))
        }
    }
    
    func runOn(cpu: Z80) {
        jump(cpu)
        
        // Never affects flag bits
    }
    
    func runOn(cpu: LR35902) {
        jump(cpu)
        
        // Never affects flag bits
    }
}