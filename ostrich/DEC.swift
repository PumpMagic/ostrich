//
//  DEC.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


// DEC is split into 8-bit and 16-bit groups here because it only affects flags when working with
// 8-bit operands


/// Decrement an 8-bit operand
struct DEC8<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.WriteType: IntegerType, T.ReadType == UInt8>: Instruction {
    let operand: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        let oldValue = operand.read()
        let newValue = oldValue &- 1
        operand.write(newValue)
        
        self.modifyFlags(z80, oldValue: oldValue, newValue: newValue)
    }
    
    func modifyFlags(z80: Z80, oldValue: T.ReadType, newValue: T.ReadType) {
        // S is set if result is negative; otherwise, it is reset.
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if borrow from bit 4, otherwise, it is reset.
        // P/V is set if m was 80h before operation; otherwise, it is reset.
        // N is set.
        // C is not affected.
        
        z80.SF.write(numberIsNegative(newValue))
        z80.ZF.write(newValue == 0x00)
        z80.HF.write(oldValue == 0x10)
        z80.PVF.write(oldValue == 0x80)
        z80.NF.write(true)
    }
}

/// Decrement a 16-bit operand
struct DEC16<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.WriteType: IntegerType, T.ReadType == UInt16>: Instruction {
    let operand: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        operand.write(operand.read() &- 1)
    }
}