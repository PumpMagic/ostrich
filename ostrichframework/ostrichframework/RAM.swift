//
//  RAM.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/4/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


public class RAM: HandlesReads, HandlesWrites {
    var data: Array<UInt8>
    
    /// An offset: specifies what memory location the first byte of the supplied data occupies
    let startingAddress: Address
    
    var highestAddress: Address {
        return UInt16(UInt32(self.startingAddress) + UInt32(self.data.count))
    }
    var addressRange: Range<Address> {
        return self.startingAddress ... self.highestAddress
    }
    var addressRangeString: String {
        return "\(self.startingAddress.hexString) - \(self.highestAddress.hexString)"
    }
    
    public init(size: UInt16, fillByte: UInt8, startingAddress: Address) {
        self.data = Array<UInt8>(count: Int(size), repeatedValue: fillByte)
        self.startingAddress = startingAddress
    }
    
    public convenience init(size: UInt16) {
        self.init(size: size, fillByte: 0x00, startingAddress: 0x0000)
    }
    
    func read(addr: Address) -> UInt8 {
        if addr < self.startingAddress ||
            Int(addr) > Int(self.startingAddress) + Int(self.data.count)
        {
            print("FATAL: attempt to access address \(addr.hexString) but our range is \(self.addressRangeString)")
            exit(1)
        }
        
        return self.data[Int(addr - self.startingAddress)]
    }
    
    func write(val: UInt8, to addr: Address) {
        self.data[Int(addr - self.startingAddress)] = val
    }
}