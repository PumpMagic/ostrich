//
//  DEC.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


struct DEC<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.WriteType: IntegerType>: Instruction {
    let operand: T
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("Running DEC")
        
        //@todo handle overflow
        let oldValue = operand.read()
        let newValue = oldValue &- 1
        operand.write(newValue)
        
        self.modifyFlags(z80, operandKind: operand.operandType, oldValue: oldValue, newValue: newValue)
    }
    
    func modifyFlags(z80: Z80, operandKind: OperandKind, oldValue: T.ReadType, newValue: T.ReadType) {
        // DEC affects flags only when working with 8-bit operands
        if (operandKind.is8Bit()) {
            // S is set if result is negative; otherwise, it is reset.
            // Z is set if result is 0; otherwise, it is reset.
            // H is set if borrow from bit 4, otherwise, it is reset.
            // P/V is set if m was 80h before operation; otherwise, it is reset. N is set.
            // N is set.
            // C is not affected.
            
            z80.SF.write(newValue & 0x80 == 0x80)
            z80.ZF.write(newValue == 0x00)
            z80.HF.write(oldValue == 0x10)
            z80.PVF.write(oldValue == 0x80)
            z80.NF.write(true)
        }
    }
}