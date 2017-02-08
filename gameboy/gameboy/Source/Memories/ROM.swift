//
//  ROM.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


open class ROM: Memory {
    var data: Data
    
    /// An offset: specifies what memory location the first byte of the supplied data occupies
    open let firstAddress: Address
    
    open var lastAddress: Address {
        return self.firstAddress + UInt16(self.data.count - 1)
    }
    open var addressRange: CountableClosedRange<Address> {
        return self.firstAddress ... self.lastAddress
    }
    var addressRangeString: String {
        return "\(self.firstAddress.hexString) - \(self.lastAddress.hexString)"
    }
    
    public init(data: Data, firstAddress: Address) {
        self.data = data
        self.firstAddress = firstAddress
        
        let overflowedMaxAddress: UInt32 = UInt32(self.firstAddress) + UInt32(self.data.count) - 1
        if overflowedMaxAddress > 0xFFFF {
            print("FATAL: ROM too large! Overflowed max address is \(overflowedMaxAddress)")
            exit(1)
        }
    }
    
    public convenience init(data: Data) {
        self.init(data: data, firstAddress: 0)
    }
    
    open func read(_ addr: Address) -> UInt8 {
        if addr < self.firstAddress ||
            Int(addr) > Int(self.firstAddress) + Int(self.data.count)
        {
            print("FATAL: attempt to access address \(addr.hexString) but our range is \(self.addressRangeString)")
            exit(1)
        }
        
        var readByte: UInt8 = 0
        (data as NSData).getBytes(&readByte, range: NSMakeRange(Int(addr-self.firstAddress), 1))
        return readByte
    }
}
