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
    func write(val: WriteType)
}

enum OperandKind {
    case Register8Like
    case Register16Like
    case Register16Indirect8Like
    case Register16ComputedLike
    case Memory8Like
    case Memory16Like
    case Immediate8Like
    case Immediate16Like
    case Indexed16Like
    
    func is8Bit() -> Bool{
        switch self {
        case .Register8Like, .Register16Indirect8Like, .Memory8Like, .Immediate8Like:
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