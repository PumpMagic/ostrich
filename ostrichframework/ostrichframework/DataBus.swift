//
//  DataBus.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/4/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


typealias AddressRange = Range<Address>

protocol DelegatesReads: HandlesReads {
    func registerReadable(readable: HandlesReads, range: Range<Address>)
}
protocol DelegatesWrites: HandlesWrites {
    func registerWriteable(writeable: HandlesWrites, range: Range<Address>)
}

class DataBus: DelegatesReads, DelegatesWrites {
    var readables: [(HandlesReads, AddressRange)]
    var writeables: [(HandlesWrites, AddressRange)]
    
    init() {
        self.readables = [(HandlesReads, AddressRange)]()
        self.writeables = [(HandlesWrites, AddressRange)]()
    }
    
    func registerReadable(readable: HandlesReads, range: Range<Address>) {
        self.readables.append((readable, range))
    }
    func registerWriteable(writeable: HandlesWrites, range: Range<Address>) {
        self.writeables.append((writeable, range))
    }
    
    func read(addr: Address) -> UInt8 {
        for (readable, range) in self.readables {
            if range ~= addr {
                return readable.read(addr)
            }
        }
        
        print("FATAL: no listeners found for read")
        exit(1)
    }
    
    func write(val: UInt8, to addr: Address) {
        for (writeable, range) in self.writeables {
            if range ~= addr {
                writeable.write(val, to: addr)
                return
            }
        }
        
        print("FATAL: no listeners found for write")
        exit(1)
    }
    
    
    // Convenience functions
    func readSigned(addr: Address) -> Int8 {
        return Int8(bitPattern: self.read(addr))
    }
    
    /// Reads two bytes of memory and returns them in host endianness
    func read16(addr: Address) -> UInt16 {
        let low = self.read(addr)
        let high = self.read(addr+1)
        
        return make16(high: high, low: low)
    }
    
    /// Writes two bytes of memory (given in host endianness)
    func write16(val: UInt16, to addr: Address) {
        self.write(getLow(val), to: addr)
        self.write(getHigh(val), to: addr+1)
    }
}