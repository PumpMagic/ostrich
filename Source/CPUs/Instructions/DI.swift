//
//  DI.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/5/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


struct DI: Z80Instruction, LR35902Instruction {
    let cycleCount: Int = 0
    
    func runOn(cpu: Z80) {
        cpu.instructionContext.lastInstructionWasDI = true
    }
    
    func runOn(cpu: LR35902) {
        cpu.instructionContext.lastInstructionWasDI = true
    }
}