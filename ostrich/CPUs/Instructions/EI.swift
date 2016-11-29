//
//  EI.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/5/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


struct EI: Z80Instruction, LR35902Instruction {
    let cycleCount: Int = 0
    
    func runOn(_ cpu: Z80) {
        cpu.instructionContext.lastInstructionWasEI = true
    }
    
    func runOn(_ cpu: LR35902) {
        cpu.instructionContext.lastInstructionWasEI = true
    }
}
