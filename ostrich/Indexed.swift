//
//  Indexed.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// A reference to a register and an 8-bit offset that together form a target address.
/// Reading this type computes this address and reads it as a `UInt8`.
/// @warn this type's `memory` member will be insufficient when bank switching is implemented
class Indexed8<T: RegisterType where T.ReadType == Address>: Readable, Writeable, OperandType {
    let register: T
    let displacement: Int8
    let memory: Memory
    
    init(register: T, displacement: Int8, memory: Memory) {
        self.register = register
        self.displacement = displacement
        self.memory = memory
    }
    
    func resolveAddress() -> Address {
        return Address(Int32(register.read()) + Int32(displacement))
    }
    
    func read() -> UInt8 {
        // (I[x/y] + d)
        return memory.read8(self.resolveAddress())
    }
    
    func write(val: UInt8) {
        memory.write8(val, to: self.resolveAddress())
    }
    
    var operandType: OperandKind {
        return OperandKind.Indexed16Like
    }
}

/// A reference to a register and an 8-bit offset that together form a target address.
/// Reading this type computes this address and reads it as a `UInt16`.
/// @warn this type's `memory` member will be insufficient when bank switching is implemented
class Indexed16<T: RegisterType where T.ReadType == Address>: Readable, Writeable, OperandType {
    let register: T
    let displacement: Int8
    let memory: Memory
    
    init(register: T, displacement: Int8, memory: Memory) {
        self.register = register
        self.displacement = displacement
        self.memory = memory
    }
    
    func resolveAddress() -> Address {
        return Address(Int32(register.read()) + Int32(displacement))
    }
    
    func read() -> UInt16 {
        // (I[x/y] + d)
        return memory.read16(self.resolveAddress())
    }
    
    func write(val: UInt16) {
        memory.write16(val, to: self.resolveAddress())
    }
    
    var operandType: OperandKind {
        return OperandKind.Indexed16Like
    }
}