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
    
    enum TransactionDirection {
        case Read
        case Write
    }
    struct Transaction: CustomStringConvertible {
        let direction: TransactionDirection
        let address: Address
        let number: UInt8
        
        var description: String {
            switch direction {
            case .Read:
                return "\(address.hexString) -> \(number.hexString)"
            case .Write:
                return "\(address.hexString) <- \(number.hexString)"
            }
        }
    }
    let logTransactions: Bool = true
    var transactions: [Transaction] = []
    
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
                let val = readable.read(addr)
                
                if self.logTransactions {
                    if addr > 0x7FFF {
                        let transaction = Transaction(direction: .Read, address: addr, number: val)
                        self.transactions.append(transaction)
                    }
                }
                
                return val
            }
        }
        
        // Hack: implement divider register here
        // Increments at 16384Hz, or ABOUT once every 61 microseconds
        // 8-bit value -> overflows at (16384/256) = 64Hz
        //@todo don't be so sloppy
        if addr == 0xFF04 {
            let secs = NSDate().timeIntervalSince1970
            let remainder = secs - round(secs)
            let us = remainder*1000000
            return UInt8(truncatingBitPattern: (Int((us/61) % 255)))
        }
        
        print("FATAL: no one listening to read of address \(addr.hexString)")
        exit(1)
    }
    
    public func write(val: UInt8, to addr: Address) {
        for (writeable, range) in self.writeables {
            if range ~= addr {
                writeable.write(val, to: addr)
                
                if self.logTransactions {
                    let transaction = Transaction(direction: .Write, address: addr, number: val)
                    self.transactions.append(transaction)
                }
                
                return
            }
        }
        
        // Hack: memory bank controller is unimplemented for now; ignore communication with it
        //@todo implement the memory bank controller
        if 0x0000 ... 0x7FFF as Range<Address> ~= addr {
            print("WARNING! Ignoring memory bank controller communication in the form of writing \(val.hexString) to \(addr.hexString)")
            if 0x0000 ... 0x1FFF as Range<Address> ~= addr {
                print("(external RAM control)")
            }
            return
        }
        
        print("FATAL: no one listening to write of \(val.hexString) to address \(addr.hexString)")
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
    
    public func dumpTransactions() {
        print(self.transactions)
    }
    
    public func clearTransactions() {
        self.transactions = []
    }
}