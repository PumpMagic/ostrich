//
//  Immediates.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


struct Immediate8: Readable, OperandType {
    let val: UInt8
    
    func read() -> UInt8 {
        return val
    }
    
    var operandType: OperandKind {
        return OperandKind.Immediate8Like
    }
}

struct Immediate8Signed: Readable, OperandType {
    let val: Int8
    
    func read() -> Int8 {
        return val
    }
    
    var operandType: OperandKind {
        return OperandKind.Immediate8Like
    }
}

struct Immediate16: Readable, OperandType {
    let val: UInt16
    
    func read() -> UInt16 {
        return val
    }
    
    var operandType: OperandKind {
        return OperandKind.Immediate16Like
    }
}

//@warn this doesn't feel like a "real" operand type. like JR should just have an associated displacement
/// An immediate and a displacement that form an immediate when added
struct ImmediateDisplaced16: Readable, OperandType {
    let base: UInt16
    let displacement: Int8
    
    func read() -> UInt16 {
        return UInt16(Int(base) + Int(displacement))
    }
    
    var operandType: OperandKind {
        return OperandKind.ImmediateDisplaced16Like
    }
}