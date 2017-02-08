//
//  Operand.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Something that can be resolved to a given type
protocol Readable {
    /// The type the implementor will resolve to when read
    associatedtype ReadType
    
    /// Read the value. Returns host endianness
    func read() -> ReadType
}

/// Something that can be written to with a given type
protocol Writeable {
    /// The type that can be written to the implementor
    associatedtype WriteType
    
    /// Write a value. Value is treated as though it has host endianness
    func write(_ val: WriteType)
}

enum OperandKind {
    case register8Like
    case register16Like
    case register16Indirect8Like
    case register16ComputedLike
    case memory8Like
    case memory16Like
    case immediate8Like
    case immediate16Like
    case immediateDisplaced16Like
    case indexed16Like
    
    func is8Bit() -> Bool{
        switch self {
        case .register8Like, .register16Indirect8Like, .memory8Like, .immediate8Like:
            return true
        default:
            return false
        }
    }
}



/// Something that is an operand; this protocol exists to expose the operand's type at runtime
protocol OperandType {
    var operandType: OperandKind { get }
}
