//
//  Instruction.swift
//  ostrich
//
//  Created by Ryan Conway on 2/21/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Instructions
protocol Instruction {
    var cycleCount: Int { get }
}

protocol Z80Instruction: Instruction {
    func runOn(z80: Z80)
}

protocol LR35902Instruction: Instruction {
    func runOn(lr35902: LR35902)
}

/// Condition: a flag and a target value
struct Condition {
    let flag: Flag
    let target: Bool
    
    func evaluate() -> Bool {
        return self.flag.read() == target
    }
}
