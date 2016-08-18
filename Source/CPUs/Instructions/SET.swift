//
//  SET.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/15/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Set a given bit of an operand
struct SET
    <T: protocol<Readable, Writeable, OperandType> where T.ReadType == UInt8, T.WriteType == T.ReadType>: Z80Instruction, LR35902Instruction
{
    let op: T
    let bit: UInt8
    
    let cycleCount = 0
    
    
    func runOn(cpu: Z80) {
        op.write(setBit(op.read(), bit: bit))
    }
    
    func runOn(cpu: LR35902) {
        op.write(setBit(op.read(), bit: bit))
    }
}