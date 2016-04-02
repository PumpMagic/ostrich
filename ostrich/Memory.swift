//
//  Memory.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


public typealias Address = UInt16

public class Memory {
    var data: NSData
    
    /// An offset: specifies what memory location the first byte of the supplied data occupies
    let startingAddress: Address
    
    var highestAddress: Address {
        return UInt16(UInt32(self.startingAddress) + UInt32(self.data.length))
    }
    var addressRange: String {
        return "\(self.startingAddress.hexString) - \(self.highestAddress.hexString)"
    }
    
    public init(data: NSData, startingAddress: Address) {
        self.data = data
        self.startingAddress = startingAddress
    }
    
    public convenience init(data: NSData) {
        self.init(data: data, startingAddress: 0)
    }
    
    func read8(addr: Address) -> UInt8 {
        if addr < self.startingAddress ||
            Int(addr) > Int(self.startingAddress) + Int(self.data.length)
        {
            print("FATAL: attempt to access address \(addr.hexString) but our range is \(self.addressRange)")
            exit(1)
        }
        
        var readByte: UInt8 = 0
        data.getBytes(&readByte, range: NSMakeRange(Int(addr-self.startingAddress), 1))
        return readByte
    }
    
    func read8Signed(addr: Address) -> Int8 {
        return Int8(bitPattern: read8(addr))
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
struct Memory8Translator: Readable, Writeable {
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
struct Memory16Translator: Readable, Writeable {
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