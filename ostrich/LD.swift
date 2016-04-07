//
//  LD.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Load: store an operand in another operand.
struct LD
    <T: protocol<Writeable, OperandType>,
    U: protocol<Readable, OperandType>
    where T.WriteType == U.ReadType>: Z80Instruction, LR35902Instruction
{
    let dest: T
    let src: U
    
    let cycleCount = 0
    
    private func load(cpu: Intel8080Like) {
        dest.write(src.read())
    }
    
    func runOn(cpu: Z80) {
        load(cpu)
    }
    
    func runOn(cpu: LR35902) {
        load(cpu)
    }
}

//@todo make special instructions for LD A, I and LD A, R, which both modify flags