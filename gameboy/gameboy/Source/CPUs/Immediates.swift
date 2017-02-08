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
        return OperandKind.immediate8Like
    }
}

struct Immediate8Signed: Readable, OperandType {
    let val: Int8
    
    func read() -> Int8 {
        return val
    }
    
    var operandType: OperandKind {
        return OperandKind.immediate8Like
    }
}

struct Immediate16: Readable, OperandType {
    let val: UInt16
    
    func read() -> UInt16 {
        return val
    }
    
    var operandType: OperandKind {
        return OperandKind.immediate16Like
    }
}
