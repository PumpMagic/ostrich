//
//  DJNZ.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/30/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Jump conditionally based on a register rather than a flag
struct DJNZ: Z80Instruction {
    // B ← B–1
    // If B = 0, continue
    // If B ≠ 0, PC ← PC + e
    
    let cycleCount = 0
    
    let displacementMinusTwo: Int8
    
    func runOn(cpu: Z80) {
        let newValue = dec(cpu.B.read())
        
        cpu.B.write(newValue)
        
        if newValue != 0 {
            //@todo bounds check
            cpu.PC.write(UInt16(Int32(cpu.PC.read()) + Int32(displacementMinusTwo) + 2))
        }
    }
    
    // doesn't affect flags
}