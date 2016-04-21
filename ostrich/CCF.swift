//
//  CCF.swift
//  ostrich
//
//  Created by Ryan Conway on 3/30/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Invert the Carry flag
struct CCF: Z80Instruction, LR35902Instruction {
    // CY ← !CY
    
    let cycleCount = 0
    
    func runOn(cpu: Z80) {
        self.modifyFlags(cpu)
    }
    
    func runOn(cpu: LR35902) {
        self.modifyFlags(cpu)
    }
    
    
    private func modifyCommonFlags(cpu: Intel8080Like) {
        // Z is not affected.
        // H behavior is different between Z80 and LR35902!!
        // N is reset.
        // C is set if CY was 0 before operation; otherwise, it is reset.
        
        let currentCarry = cpu.CF.read()
        
        cpu.NF.write(false)
        cpu.CF.write(!currentCarry)
    }
    
    private func modifyFlags(cpu: Z80) {
        // H, previous carry is copied.
        // S is not affected.
        // P/V is not affected.
        
        let currentCarry = cpu.CF.read()
        
        cpu.HF.write(currentCarry)
        
        modifyCommonFlags(cpu)
    }
    
    private func modifyFlags(cpu: LR35902) {
        cpu.HF.write(false)
        
        modifyCommonFlags(cpu)
    }
}