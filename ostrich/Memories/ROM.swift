//
//  ROM.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


public class ROM: Memory {
    var data: NSData
    
    /// An offset: specifies what memory location the first byte of the supplied data occupies
    public let firstAddress: Address
    
    public var lastAddress: Address {
        return self.firstAddress + UInt16(self.data.length - 1 - 1)
    }
    public var addressRange: Range<Address> {
        return self.firstAddress ... self.lastAddress
    }
    var addressRangeString: String {
        return "\(self.firstAddress.hexString) - \(self.lastAddress.hexString)"
    }
    
    public init(data: NSData, firstAddress: Address) {
        self.data = data
        self.firstAddress = firstAddress
        
        let overflowedMaxAddress: UInt32 = UInt32(self.firstAddress) + UInt32(self.data.length) - 1
        if overflowedMaxAddress > 0xFFFF {
            print("FATAL: ROM too large! Overflowed max address is \(overflowedMaxAddress)")
            exit(1)
        }
    }
    
    public convenience init(data: NSData) {
        self.init(data: data, firstAddress: 0)
    }
    
    public func read(addr: Address) -> UInt8 {
        if addr < self.firstAddress ||
            Int(addr) > Int(self.firstAddress) + Int(self.data.length)
        {
            print("FATAL: attempt to access address \(addr.hexString) but our range is \(self.addressRangeString)")
            exit(1)
        }
        
        var readByte: UInt8 = 0
        data.getBytes(&readByte, range: NSMakeRange(Int(addr-self.firstAddress), 1))
        return readByte
    }
}