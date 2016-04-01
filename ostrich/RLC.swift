//
//  RLC.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/31/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Left rotate with carry
struct RLC<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.ReadType == UInt8>: Instruction
{
    let op: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        let oldValue = op.read()
        let newValue = rotateRight(oldValue)
        
        op.write(newValue)
        
        modifyFlags(z80, oldValue: oldValue, newValue: newValue)
    }
    
    func modifyFlags(z80: Z80, oldValue: UInt8, newValue: UInt8) {
        // S is set if result is negative; otherwise, it is reset.
        // Z is set if result is 0; otherwise, it is reset.
        // H is reset.
        // P/V is set if parity even; otherwise, it is reset.
        // N is reset.
        // C is data from bit 7 of source register.
        
        z80.SF.write(numberIsNegative(newValue))
        z80.ZF.write(newValue == 0x00)
        z80.HF.write(false)
        z80.PVF.write(parity(newValue))
        z80.NF.write(false)
        z80.CF.write(bitIsHigh(oldValue, bit: 7))
    }
}

/// Right rotate with carry A
struct RLCA: Instruction {
    //@warn the Z80 manual's example has something that doesn't look like a proper right rotate
    // it's probably an error in the manual, so this instruction implements an actual rotate...
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        let oldA = z80.A.read()
        
        z80.A.write(rotateLeft(oldA))
        modifyFlags(z80, oldValue: oldA)
    }
    
    func modifyFlags(z80: Z80, oldValue: UInt8) {
        // S is not affected.
        // Z is not affected.
        // H is reset.
        // P/V is not affected.
        // N is reset.
        // C is data from bit 7 of Accumulator.
        
        z80.HF.write(false)
        z80.NF.write(false)
        z80.CF.write(bitIsHigh(oldValue, bit: 7))
    }
}