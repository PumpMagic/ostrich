//
//  CCF.swift
//  ostrich
//
//  Created by Ryan Conway on 3/30/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Invert the Carry flag
struct CCF: Instruction {
    // CY ← !CY
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("Running CCF")
        
        self.modifyFlags(z80)
    }
    
    func modifyFlags(z80: Z80) {
        // S is not affected.
        // Z is not affected.
        // H, previous carry is copied.
        // P/V is not affected.
        // N is reset.
        // C is set if CY was 0 before operation; otherwise, it is reset.
        
        let currentCarry = z80.CF.read()
        
        z80.HF.write(currentCarry)
        z80.NF.write(false)
        z80.CF.write(!currentCarry)
    }
}