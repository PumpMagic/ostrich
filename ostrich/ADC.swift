//
//  ADC.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


//@todo model this after ADD
//@todo tips for genericizing flag modifications for sub: http://stackoverflow.com/questions/8034566/overflow-and-carry-flags-on-z80
/// Add with carry
struct ADC<T: protocol<Readable, OperandType>>: Instruction {
    // A <- A + s + CY
    let operand: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("Running ADC")
    }
}