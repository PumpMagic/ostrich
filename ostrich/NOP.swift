//
//  NOP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// No-op
struct NOP: Instruction {
    let cycleCount = 0 //@todo
    
    func runOn(z80: Z80) {
        // Never affects flag bits
    }
}