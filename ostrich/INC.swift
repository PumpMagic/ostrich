//
//  INC.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Increment
struct INC<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.WriteType: IntegerType>: Instruction {
    let operand: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("Running INC")
        
        //@todo handle overflow
        let oldValue = operand.read()
        let newValue = oldValue &+ 1
        operand.write(newValue)
        
        self.modifyFlags(z80, operandKind: operand.operandType, oldValue: oldValue, newValue: newValue)
    }
    
    func modifyFlags(z80: Z80, operandKind: OperandKind, oldValue: T.ReadType, newValue: T.ReadType) {
        // INC affects flags only when working with 8-bit operands
        if (operandKind.is8Bit()) {
            // S is set if result is negative; otherwise, it is reset.
            // Z is set if result is 0; otherwise, it is reset.
            // H is set if carry from bit 3; otherwise, it is reset.
            // P/V is set if r was 7Fh before operation; otherwise, it is reset.
            // N is reset.
            // C is not affected.
            
            z80.SF.write(newValue & 0x80 == 0x80)
            z80.ZF.write(newValue == 0x00)
            z80.HF.write(oldValue == 0x0F)
            z80.PVF.write(oldValue == 0x7F)
            z80.NF.write(false)
        }
    }
}