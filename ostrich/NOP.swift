//
//  NOP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// No-op
struct NOP: Z80Instruction, LR35902Instruction {
    let cycleCount = 0
    
    func runOn(cpu: Z80) {
        // Never affects flag bits
    }
    
    func runOn(cpu: LR35902) {
        // Never affects flag bits
    }
}