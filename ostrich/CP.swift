//
//  CP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Compare; subtract, but just change the flags
struct CP<T: protocol<Readable, OperandType>>: Instruction {
    let op: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("CP: Implement me!")
    }
}