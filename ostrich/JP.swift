//
//  JP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Jump
struct JP<T: protocol<Readable, OperandType> where T.ReadType == UInt16>: Instruction {
    /// Condition: if present, the jump will only happen if the flag evaluates to the boolean value
    let condition: Condition?
    
    // possible jump targets: immediate extended, relative, register
    let dest: T
    
    let cycleCount = 0 //@todo
    
    func runOn(z80: Z80) {
        print("Before JP: \n\(z80.pcsp)")
        
        // Only jump if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            z80.PC.write(dest.read())
        }
        
        // Never affects flag bits
        
        print("After JP: \n\(z80.pcsp)")
    }
}