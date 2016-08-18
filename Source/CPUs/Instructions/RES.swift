//
//  RES.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/21/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Reset a given bit of an operand
struct RES
    <T: protocol<Readable, Writeable, OperandType> where T.ReadType == UInt8, T.WriteType == T.ReadType>: Z80Instruction, LR35902Instruction
{
    let op: T
    let bit: UInt8
    
    let cycleCount = 0
    
    
    func runOn(cpu: Z80) {
        op.write(clearBit(op.read(), bit: bit))
    }
    
    func runOn(cpu: LR35902) {
        op.write(clearBit(op.read(), bit: bit))
    }
}