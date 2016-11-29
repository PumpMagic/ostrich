//
//  RAM.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/4/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


open class RAM: Memory, HandlesWrites {
    var data: Array<UInt8>
    
    /// An offset: specifies what memory location the first byte of the supplied data occupies
    open let firstAddress: Address
    
    open var lastAddress: Address {
        return UInt16(UInt32(self.firstAddress) + UInt32(self.data.count) - 1)
    }
    open var addressRange: CountableRange<Address> {
        return self.firstAddress ... self.lastAddress
    }
    var addressRangeString: String {
        return "\(self.firstAddress.hexString) - \(self.lastAddress.hexString)"
    }
    
    public init(size: UInt16, fillByte: UInt8, firstAddress: Address) {
        self.data = Array<UInt8>(repeating: fillByte, count: Int(size))
        self.firstAddress = firstAddress
    }
    
    public convenience init(size: UInt16) {
        self.init(size: size, fillByte: 0x00, firstAddress: 0x0000)
    }
    
    open func read(_ addr: Address) -> UInt8 {
        if addr < self.firstAddress ||
            Int(addr) > Int(self.firstAddress) + Int(self.data.count)
        {
            print("FATAL: attempt to access address \(addr.hexString) but our range is \(self.addressRangeString)")
            exit(1)
        }
        
        return self.data[Int(addr - self.firstAddress)]
    }
    
    open func write(_ val: UInt8, to addr: Address) {
        self.data[Int(addr - self.firstAddress)] = val
    }
    
    open func nonzeroes() -> String {
        var nonzeroes: String = ""
        
        for (index, datum) in self.data.enumerated() {
            if datum != 0x00 {
                nonzeroes += "\((firstAddress + UInt16(index)).hexString): \(datum.hexString) "
            }
        }
        
        return nonzeroes
    }
}
