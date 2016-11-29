//
//  CPL.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/30/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func invert(_ val: UInt8) -> UInt8 {
    return ~val
}

/// Invert the accumulator
struct CPL: Z80Instruction, LR35902Instruction {
    let cycleCount = 0
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) {
        let oldValue = cpu.A.read()
        let newValue = invert(oldValue)
        
        cpu.A.write(newValue)
    }
    
    func runOn(_ cpu: Z80) {
        runCommon(cpu)
        
        modifyFlags(cpu)
    }
    
    func runOn(_ cpu: LR35902) {
        runCommon(cpu)
        
        modifyFlags(cpu)
    }
    
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like) {
        // Z is not affected.
        // H is set.
        // N is set.
        // C is not affected.

        cpu.HF.write(true)
        cpu.NF.write(true)
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
