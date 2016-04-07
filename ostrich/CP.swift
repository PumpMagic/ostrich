//
//  CP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Compare; subtract, but just change the flags
struct CP<T: protocol<Readable, OperandType>>: Z80Instruction, LR35902Instruction {
    let op: T
    
    let cycleCount = 0
    
    func runOn(cpu: Z80) {
        print("FATAL: CP unimplemented")
        exit(1)
    }
    
    func runOn(cpu: LR35902) {
        print("FATAL: CP unimplemented")
        exit(1)
    }
}