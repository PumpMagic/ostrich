//
//  DJNZ.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/30/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Jump conditionally based on a register rather than a flag
struct DJNZ: Instruction {
    // B ← B–1
    // If B = 0, continue
    // If B ≠ 0, PC ← PC + e
    
    let cycleCount = 0
    
    let displacement: Int8
    
    func runOn(z80: Z80) {
        print("Running DJNZ")
        
        let newValue = z80.B.read() &- 1
        
        z80.B.write(newValue)
        
        if newValue != 0 {
            //@todo bounds check
            z80.PC.write(UInt16(Int32(z80.PC.read() + 2) + Int32(displacement)))
        }
    }
    
    // doesn't affect flags
}