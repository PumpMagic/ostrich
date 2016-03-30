//
//  Registers.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


protocol RegisterType: Readable, Writeable {}

/// An 8-bit register: some CPU-built-in memory cell that holds an 8-bit value
class Register8: RegisterType, OperandType {
    var val: UInt8
    
    init(val: UInt8) {
        self.val = val
    }
    
    func read() -> UInt8 {
        return val
    }
    
    func write(val: UInt8) {
        self.val = val
    }
    
    var operandType: OperandKind {
        return OperandKind.Register8Like
    }
}

/// A flag: a computed property that is a single bit of an 8-bit register, readable and writeable as a Bool
class Flag: Readable, Writeable {
    let reg: Register8
    let bitNumber: UInt8
    
    init(reg: Register8, bitNumber: UInt8) {
        self.reg = reg
        self.bitNumber = bitNumber
    }
    
    func read() -> Bool {
        let regVal = reg.read()
        let mask = UInt8(0x01 << bitNumber)
        
        if regVal & mask != 0 {
            return true
        }
        
        return false
    }
    
    /// not thread safe
    func write(val: Bool) {
        var newVal = reg.read()
        if val {
            let mask = UInt8(0x01 << bitNumber)
            newVal |= mask
            reg.write(newVal)
        }
    }
}

/// A 16-bit register: some CPU-built-in memory cell that holds a 16-bit value
class Register16: RegisterType, OperandType {
    var val: UInt16
    
    init(val: UInt16) {
        self.val = val
    }
    
    func read() -> UInt16 {
        return val
    }
    
    func write(val: UInt16) {
        self.val = val
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16Like
    }
}

/// A virtual 16-bit register, computed from two 8-bit registers
class Register16Computed: RegisterType, OperandType {
    let high: Register8
    let low: Register8
    
    init(high: Register8, low: Register8) {
        self.high = high
        self.low = low
    }
    
    func read() -> UInt16 {
        let highVal = self.high.read()
        let lowVal = self.low.read()
        
        return make16(high: highVal, low: lowVal)
    }
    
    func write(val: UInt16) {
        self.high.write(0)
        self.low.write(0)
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16ComputedLike
    }
}

/// A 16-bit register whose value is interpreted as an address to an 8-bit value to read from or write to.
/// @warn this type's `memory` member will be insufficient when bank switching is implemented
class Register16Indirect8<T: RegisterType where T.ReadType == UInt16>: Readable, Writeable, OperandType {
    let register: T
    let memory: Memory
    
    init(register: T, memory: Memory) {
        self.register = register
        self.memory = memory
    }
    
    func read() -> UInt8 {
        return Memory8Translator(addr: register.read(), memory: memory).read()
    }
    
    func write(val: UInt8) {
        Memory8Translator(addr: register.read(), memory: memory).write(val)
    }
    
    var operandType: OperandKind {
        return OperandKind.Register16Indirect8Like
    }
}