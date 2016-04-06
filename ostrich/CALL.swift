//
//  CALL.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/1/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Call: call a function by pushing the PC onto the stack and jumping
struct CALL<T: protocol<Readable, OperandType> where T.ReadType == UInt16>: Instruction {
    // (SP – 1) ← PCH, (SP – 2) ← PCL, PC ← nn
    
    let condition: Condition?
    let dest: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        // Only return if the condition is absent or met
        let conditionSatisfied = condition?.evaluate() ?? true
        
        if conditionSatisfied {
            z80.push(z80.PC.read())
            z80.PC.write(dest.read())
        }
    }
}