//
//  Instruction.swift
//  ostrich
//
//  Created by Ryan Conway on 2/21/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Instructions
public protocol Instruction {
    var cycleCount: Int { get }
    
    func runOn(z80: Z80)
}

/// Condition
struct Condition {
    let flag: Flag
    let target: Bool
    
    func evaluate() -> Bool {
        return self.flag.read() == target
    }
}
