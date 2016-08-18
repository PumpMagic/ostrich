//
//  CPL.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/30/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func invert(val: UInt8) -> UInt8 {
    return ~val
}

/// Invert the accumulator
struct CPL: Z80Instruction, LR35902Instruction {
    let cycleCount = 0
    
    
    private func runCommon(cpu: Intel8080Like) {
        let oldValue = cpu.A.read()
        let newValue = invert(oldValue)
        
        cpu.A.write(newValue)
    }
    
    func runOn(cpu: Z80) {
        runCommon(cpu)
        
        modifyFlags(cpu)
    }
    
    func runOn(cpu: LR35902) {
        runCommon(cpu)
        
        modifyFlags(cpu)
    }
    
    
    private func modifyCommonFlags(cpu: Intel8080Like) {
        // Z is not affected.
        // H is set.
        // N is set.
        // C is not affected.

        cpu.HF.write(true)
        cpu.NF.write(true)
    }
    
    private func modifyFlags(cpu: Z80) {
        modifyCommonFlags(cpu)
        
        // S is not affected.
        // P/V is not affected.
    }
    
    private func modifyFlags(cpu: LR35902) {
        modifyCommonFlags(cpu)
    }
}