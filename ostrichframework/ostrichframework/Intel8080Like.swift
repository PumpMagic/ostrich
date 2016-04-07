//
//  8080Like.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/6/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


struct Intel8080InstructionContext {
    var lastInstructionWasDI: Bool
    var lastInstructionWasEI: Bool
}

enum FlipFlop {
    case Enabled
    case Disabled
}

/// Everything in common between the Z80 and the LR35902.
protocol Intel8080Like {
    var A: Register8 { get }
    var B: Register8 { get }
    var C: Register8 { get }
    var D: Register8 { get }
    var E: Register8 { get }
    var F: Register8 { get }
    var H: Register8 { get }
    var L: Register8 { get }
    
    var I: Register8 { get }
    var R: Register8 { get }
    
    var SP: Register16 { get }
    var PC: Register16 { get }
    
    var ZF: Flag { get }
    var NF: Flag { get }
    var HF: Flag { get }
    var CF: Flag { get }
    
    var IFF1: FlipFlop { get }
    var IFF2: FlipFlop { get }
    
    var bus: DataBus { get }
    
    func push(val: UInt16)
    func pop() -> UInt16
}

extension Intel8080Like {
    /// Push a two-byte value onto the stack.
    /// Adjusts the stack pointer accordingly.
    func push(val: UInt16) {
        let oldAddr = self.SP.read()
        let newAddr = oldAddr - 2
        
        self.SP.write(newAddr)
        
        self.bus.write16(val, to: newAddr)
    }
    
    func pop() -> UInt16 {
        let addr = self.SP.read()
        let val = self.bus.read16(addr)
        
        self.SP.write(addr + 2)
        return val
    }
}