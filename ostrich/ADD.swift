//
//  ADD.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/31/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


//@todo consider splitting this into ADD8 and ADD16, because 8-bit adds and 16-bit ADDs
//modify flags differently
//if we do this, also split existing classes like DEC

/// Add
struct ADD
    <T: protocol<Readable, Writeable, OperandType>, U: protocol<Readable, OperandType>
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType: IntegerType>: Instruction
{
    let op1: T
    let op2: U
    
    let cycleCount = 0
    
    func runOn(z80: Z80) {
        print("Running ADD")
        
        op1.write(op1.read() &+ op2.read())
    }
    
    //@todo these two flag modification combinations *probably* cover everything... but do they?
    func modifyFlags(z80: Z80, operandKind: OperandKind, oldValue: T.ReadType, newValue: T.ReadType) {
        if (operandKind.is8Bit()) {
            // S is set if result is negative; otherwise, it is reset.
            // Z is set if result is 0; otherwise, it is reset.
            // H is set if carry from bit 3; otherwise, it is reset.
            // P/V is set if overflow; otherwise, it is reset.
            // N is reset.
            // C is set if carry from bit 7; otherwise, it is reset.
        } else {
            // S is not affected.
            // Z is not affected.
            // H is set if carry from bit 11; otherwise, it is reset.
            // P/V is not affected.
            // N is reset.
            // C is set if carry from bit 15; otherwise, it is reset.
        }
    }
}