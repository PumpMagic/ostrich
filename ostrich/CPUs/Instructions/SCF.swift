//
//  SCF.swift
//  ostrichframework
//
//  Created by Ryan Conway on 5/3/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Set the Carry flag
struct SCF: Z80Instruction, LR35902Instruction {
    // CY ← !CY
    
    let cycleCount = 0
    
    func runOn(_ cpu: Z80) {
        self.modifyFlags(cpu)
    }
    
    func runOn(_ cpu: LR35902) {
        self.modifyFlags(cpu)
    }
    
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like) {
        // Z is not affected.
        // H is reset.
        // N is reset.
        // C is set.
        
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(true)
    }
    
    fileprivate func modifyFlags(_ cpu: Z80) {
        modifyCommonFlags(cpu)
        
        // S is not affected.
        // P/V is not affected.
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902) {
        modifyCommonFlags(cpu)
    }
}
