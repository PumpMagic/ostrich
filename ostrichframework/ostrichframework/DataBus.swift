//
//  DataBus.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/4/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


protocol DelegatesReads: HandlesReads {
    func registerReadable(readable: protocol<BusListener, HandlesReads>)
}
protocol DelegatesWrites: HandlesWrites {
    func registerWriteable(writeable: protocol<BusListener, HandlesWrites>)
}

public class DataBus: DelegatesReads, DelegatesWrites {
    var readables: [(HandlesReads, Range<Address>)]
    var writeables: [(HandlesWrites, Range<Address>)]
    
    public init() {
        self.readables = [(HandlesReads, Range<Address>)]()
        self.writeables = [(HandlesWrites, Range<Address>)]()
    }
    
    public func registerReadable(readable: protocol<BusListener, HandlesReads>) {
        self.readables.append((readable, readable.addressRange))
    }
    public func registerWriteable(writeable: protocol<BusListener, HandlesWrites>) {
        self.writeables.append((writeable, writeable.addressRange))
    }
    
    public func read(addr: Address) -> UInt8 {
        for (readable, range) in self.readables {
            if range ~= addr {
                return readable.read(addr)
            }
        }
        
        print("FATAL: no listeners found for read of \(addr.hexString)")
        exit(1)
    }
    
    public func write(val: UInt8, to addr: Address) {
        for (writeable, range) in self.writeables {
            if range ~= addr {
                writeable.write(val, to: addr)
                return
            }
        }
        
        print("FATAL: no listeners found for write of \(addr.hexString)")
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