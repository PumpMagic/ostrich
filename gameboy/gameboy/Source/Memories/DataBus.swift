//
//  DataBus.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/4/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


protocol DelegatesReads: HandlesReads {
    func connectReadable(_ readable: BusListener & HandlesReads)
}
protocol DelegatesWrites: HandlesWrites {
    func connectWriteable(_ writeable: BusListener & HandlesWrites)
}

/// A data bus that connects any numbers of peripherals.
open class DataBus: DelegatesReads, DelegatesWrites {
    //@todo consider using Intervals instead of Ranges:
    //http://oleb.net/blog/2015/09/swift-ranges-and-intervals/
    /// (ID, peripheral, address range)
    var readables: [(HandlesReads, CountableClosedRange<Address>, String?)]
    var writeables: [(HandlesWrites, CountableClosedRange<Address>, String?)]
    
    enum TransactionDirection {
        case read
        case write
    }
    struct Transaction: CustomStringConvertible {
        let direction: TransactionDirection
        let address: Address
        let number: UInt8
        
        var description: String {
            switch direction {
            case .read:
                return "\(address.hexString) -> \(number.hexString)"
            case .write:
                return "\(address.hexString) <- \(number.hexString)"
            }
        }
    }
    let logTransactions: Bool = false
    var transactions: [Transaction] = []
    
    public init() {
        self.readables = [(HandlesReads, CountableClosedRange<Address>, String?)]()
        self.writeables = [(HandlesWrites, CountableClosedRange<Address>, String?)]()
    }
    
    open func connectReadable(_ readable: BusListener & HandlesReads) {
        self.readables.append((readable, readable.addressRange, nil))
    }
    open func connectWriteable(_ writeable: BusListener & HandlesWrites) {
        self.writeables.append((writeable, writeable.addressRange, nil))
    }
    
    open func connectReadable(_ readable: BusListener & HandlesReads, id: String) {
        self.readables.append((readable, readable.addressRange, id))
    }
    
    open func connectWriteable(_ readable: BusListener & HandlesWrites, id: String) {
        self.writeables.append((readable, readable.addressRange, id))
    }
    
    open func disconnectReadable(id: String) {
        var elementFound: Bool
        
        repeat {
            elementFound = false
            for (index, (_, _, elementID)) in self.readables.enumerated() {
                if elementID == id {
                    self.readables.remove(at: index)
                    elementFound = true
                    break
                }
            }
        } while elementFound
    }
    
    //@todo the logic here is duplicated with disconnectReadable().
    // This is because there's no common type between self.readables and self.writeables.
    open func disconnectWriteable(id: String) {
        var elementFound: Bool
        
        repeat {
            elementFound = false
            for (index, (_, _, elementID)) in self.writeables.enumerated() {
                if elementID == id {
                    self.readables.remove(at: index)
                    elementFound = true
                    break
                }
            }
        } while elementFound
    }
    
    
    
    open func read(_ addr: Address) -> UInt8 {
        for (readable, range, _) in self.readables {
            if range ~= addr {
                let val = readable.read(addr)
                
                if self.logTransactions {
                    if addr > 0x7FFF {
                        let transaction = Transaction(direction: .read, address: addr, number: val)
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
            let secs = Date().timeIntervalSince1970
            let remainder = secs - round(secs)
            let us = remainder*1000000
            return UInt8(truncatingBitPattern: (Int((us/61).truncatingRemainder(dividingBy: 255))))
        }
        
        // Hack: implement echo RAM here
        // 0xE000 - 0xFDFF is an echo of 0xC000 - 0xDDFF.
        // Nintendo said not to use it, but apparently some games did anyway
        if Address(0xE000) ... Address(0xFDFF) ~= addr {
            print("WARNING: attempt to use echo RAM. Parsing failure?")
            return self.read(addr - 0x2000)
        }
        
        //print("WARNING: no one listening to read of address \(addr.hexString)")
        //@todo probably shouldn't return 0
        return 0
        //exit(1)
    }
    
    open func write(_ val: UInt8, to addr: Address) {
        for (writeable, range, _) in self.writeables {
            if range ~= addr {
                writeable.write(val, to: addr)
                
                if self.logTransactions {
                    let transaction = Transaction(direction: .write, address: addr, number: val)
                    self.transactions.append(transaction)
                }
                
                return
            }
        }
        
        // Hack: memory bank controller is unimplemented for now; ignore communication with it
        //@todo implement the memory bank controller
        if Address(0x0000) ... Address(0x7FFF) ~= addr {
            print("WARNING! Ignoring memory bank controller communication in the form of writing \(val.hexString) to \(addr.hexString)")
            if Address(0x0000) ... Address(0x1FFF) ~= addr {
                print("(external RAM control)")
            }
            return
        }
        
        print("WARNING: no one listening to write of \(val.hexString) to address \(addr.hexString)")
        //@todo actually exit
//        exit(1)
    }
    
    
    // Convenience functions
    func readSigned(_ addr: Address) -> Int8 {
        return Int8(bitPattern: self.read(addr))
    }
    
    /// Reads two bytes of memory and returns them in host endianness
    func read16(_ addr: Address) -> UInt16 {
        let low = self.read(addr)
        let high = self.read(addr+1)
        
        return make16(high: high, low: low)
    }
    
    /// Writes two bytes of memory (given in host endianness)
    func write16(_ val: UInt16, to addr: Address) {
        self.write(getLow(val), to: addr)
        self.write(getHigh(val), to: addr+1)
    }
    
    open func dumpTransactions() {
        print(self.transactions)
    }
    
    open func clearTransactions() {
        self.transactions = []
    }
    
    func clearAllWriteables() {
        for (writeable, range, _) in self.writeables {
            for addr in range {
                writeable.write(0, to: addr)
            }
        }
    }
}
