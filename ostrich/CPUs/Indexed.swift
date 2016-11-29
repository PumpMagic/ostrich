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
class Indexed8<T: RegisterType>: Readable, Writeable, OperandType where T.ReadType == Address {
    let register: T
    let displacement: Int8
    let bus: DataBus
    
    init(register: T, displacement: Int8, bus: DataBus) {
        self.register = register
        self.displacement = displacement
        self.bus = bus
    }
    
    func resolveAddress() -> Address {
        return Address(Int32(register.read()) + Int32(displacement))
    }
    
    func read() -> UInt8 {
        // (I[x/y] + d)
        return bus.read(self.resolveAddress())
    }
    
    func write(_ val: UInt8) {
        bus.write(val, to: self.resolveAddress())
    }
    
    var operandType: OperandKind {
        return OperandKind.indexed16Like
    }
}

/// A reference to a register and an 8-bit offset that together form a target address.
/// Reading this type computes this address and reads it as a `UInt16`.
/// @warn this type's `memory` member will be insufficient when bank switching is implemented
class Indexed16<T: RegisterType>: Readable, Writeable, OperandType where T.ReadType == Address {
    let register: T
    let displacement: Int8
    let bus: DataBus
    
    init(register: T, displacement: Int8, bus: DataBus) {
        self.register = register
        self.displacement = displacement
        self.bus = bus
    }
    
    func resolveAddress() -> Address {
        return Address(Int32(register.read()) + Int32(displacement))
    }
    
    func read() -> UInt16 {
        // (I[x/y] + d)
        return bus.read16(self.resolveAddress())
    }
    
    func write(_ val: UInt16) {
        bus.write16(val, to: self.resolveAddress())
    }
    
    var operandType: OperandKind {
        return OperandKind.indexed16Like
    }
}
