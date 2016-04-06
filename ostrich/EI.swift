//
//  EI.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/5/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


struct EI: Instruction {
    let cycleCount: Int = 0
    
    func runOn(z80: Z80) {
        z80.instructionContext.lastInstructionWasEI = true
    }
}