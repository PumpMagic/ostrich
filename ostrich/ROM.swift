//
//  ROM.swift
//  ostrich
//
//  Created by Ryan Conway on 3/28/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


public class ROM: HandlesReads {
    var data: NSData
    
    /// An offset: specifies what memory location the first byte of the supplied data occupies
    let startingAddress: Address
    
    var highestAddress: Address {
        return UInt16(UInt32(self.startingAddress) + UInt32(self.data.length))
    }
    var addressRange: Range<Address> {
        return self.startingAddress ... self.highestAddress
    }
    var addressRangeString: String {
        return "\(self.startingAddress.hexString) - \(self.highestAddress.hexString)"
    }
    
    public init(data: NSData, startingAddress: Address) {
        self.data = data
        self.startingAddress = startingAddress
    }
    
    public convenience init(data: NSData) {
        self.init(data: data, startingAddress: 0)
    }
    
    func read(addr: Address) -> UInt8 {
        if addr < self.startingAddress ||
            Int(addr) > Int(self.startingAddress) + Int(self.data.length)
        {
            print("FATAL: attempt to access address \(addr.hexString) but our range is \(self.addressRangeString)")
            exit(1)
        }
        
        var readByte: UInt8 = 0
        data.getBytes(&readByte, range: NSMakeRange(Int(addr-self.startingAddress), 1))
        return readByte
    }
}