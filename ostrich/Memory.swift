//
//  Memory.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


typealias Address = UInt16

public class Memory {
    var data: NSData
    
    public init(data: NSData) {
        self.data = data
    }
    
    func read8(addr: Address) -> UInt8 {
        var readByte: UInt8 = 0
        /*@todo validate bound beforehand, swift can't catch obj-c exceptions
         do {
         try data.getBytes(&readByte, range: NSMakeRange(Int(addr), 1))
         return readByte
         } catch NSRangeException {
         return nil
         }
         */
        data.getBytes(&readByte, range: NSMakeRange(Int(addr), 1))
        return readByte
    }
    
    /// Reads two bytes of memory and returns them in host endianness
    func read16(addr: Address) -> UInt16 {
        let low = read8(addr)
        let high = read8(addr+1)
        
        return make16(high: high, low: low)
    }
    
    func write8(val: UInt8, to addr: Address) {
        
    }
    
    /// Writes two bytes to memory. Expects value in host endianness
    func write16(val: UInt16, to addr: Address) {
        
    }
}

/// An 8-bit window into a Memory
struct Memory8Translator: Readable, Writeable /*@todo are these really operands?, OperandType*/ {
    var addr: Address
    let memory: Memory
    
    func read() -> UInt8 {
        return memory.read8(addr)
    }
    
    func write(val: UInt8) {
        memory.write8(val, to: addr)
    }
    
    var operandType: OperandKind {
        return OperandKind.Memory8Like
    }
}

/// A 16-bit window into a Memory
struct Memory16Translator: Readable, Writeable /*@todo are these really operands?, OperandType*/ {
    var addr: Address
    let memory: Memory
    
    func read() -> UInt16 {
        return memory.read16(addr)
    }
    
    func write(val: UInt16) {
        memory.write16(val, to: addr)
    }
    
    var operandType: OperandKind {
        return OperandKind.Memory16Like
    }
}