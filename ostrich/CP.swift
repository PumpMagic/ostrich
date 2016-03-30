//
//  CP.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


struct CP<T: protocol<Readable, OperandType>>: Instruction {
    // Compare; subtract, but just change the flags
    let op: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("CP: Implement me!")
    }
}