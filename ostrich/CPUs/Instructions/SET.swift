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
    <T: Readable & Writeable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == UInt8, T.WriteType == T.ReadType
{
    let op: T
    let bit: UInt8
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: Z80) {
        op.write(setBit(op.read(), bit: bit))
    }
    
    func runOn(_ cpu: LR35902) {
        op.write(setBit(op.read(), bit: bit))
    }
}
