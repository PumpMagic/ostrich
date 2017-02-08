//
//  RST.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/30/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Restart: push PC onto the stack, then set PC to a constant
struct RST: Z80Instruction, LR35902Instruction {
    // (SP – 1) ← PCH, (SP – 2) ← PCL, PCH ← 0, PCL ← P
    //@todo consider validating the constant: valid values are 0x00, 0x08, 0x10, 0x18 ... 0x38
    
    let cycleCount = 0
    
    let restartAddress: Address
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) {
        cpu.push(cpu.PC.read())
        cpu.PC.write(restartAddress)
    }
    
    func runOn(_ cpu: Z80) {
        runCommon(cpu)
    }
    
    func runOn(_ cpu: LR35902) {
        runCommon(cpu)
    }
}
