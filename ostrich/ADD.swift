//
//  ADD.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/31/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func add<T: IntegerType>(v1: T, _ v2: T) -> T {
    return v1 &+ v2
}

private func addAndStore
    <T: protocol<Readable, Writeable>, U: Readable
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType: IntegerType>
    (op1: T, _ op2: U)
    -> (T.ReadType, U.ReadType, T.WriteType)
{
    let op1v = op1.read()
    let op2v = op2.read()
    let result = add(op1v, op2v)
    op1.write(result)
    
    return (op1v, op2v, result)
}


/// Add two 8-bit operands; overwrite the first with the result
struct ADD8
    <T: protocol<Readable, Writeable, OperandType>, U: protocol<Readable, OperandType>
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType == UInt8>: Z80Instruction, LR35902Instruction
{
    let op1: T
    let op2: U
    
    let cycleCount = 0
    
    
    func runOn(z80: Z80) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(z80, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(lr35902: LR35902) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(lr35902, op1: op1v, op2: op2v, result: result)
    }
    
    func modifyFlags(z80: Z80, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        // S is set if result is negative; otherwise, it is reset.
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if carry from bit 3; otherwise, it is reset.
        // P/V is set if overflow; otherwise, it is reset.
        // N is reset.
        // C is set if carry from bit 7; otherwise, it is reset.
        
        z80.SF.write(numberIsNegative(result))
        z80.ZF.write(result == 0)
        z80.HF.write(addHalfCarryProne(op1, op2))
        z80.PVF.write(addOverflowOccurred(op1, op2, result: result))
        z80.NF.write(false)
        z80.CF.write(addCarryProne(op1, op2))
    }
    
    func modifyFlags(lr35902: LR35902, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        // Z - Set if result is zero.
        // N - Reset.
        // H - Set if carry from bit 3.
        // C - Set if carry from bit 7.
        
        lr35902.ZF.write(result == 0x00)
        lr35902.NF.write(false)
        lr35902.HF.write(addHalfCarryProne(op1, op2))
        lr35902.CF.write(addCarryProne(op1, op2))
    }
}

/// Add two 16-bit operands; overwrite the first with the result
struct ADD16
    <T: protocol<Readable, Writeable, OperandType>, U: protocol<Readable, OperandType>
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType == UInt16>: Z80Instruction, LR35902Instruction
{
    let op1: T
    let op2: U
    
    let cycleCount = 0
    
    
    func runOn(z80: Z80) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(z80, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(lr35902: LR35902) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(lr35902, op1: op1v, op2: op2v, result: result)
    }
    
    func modifyFlags(z80: Z80, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        // S is not affected.
        // Z is not affected.
        // H is set if carry from bit 11; otherwise, it is reset.
        // P/V is not affected.
        // N is reset.
        // C is set if carry from bit 15; otherwise, it is reset.
        
        z80.HF.write(addHalfCarryProne(op1, op2: op2))
        z80.NF.write(false)
        z80.CF.write(addCarryProne(op1, op2: op2))
    }
    
    func modifyFlags(lr35902: LR35902, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        // Z - Not affected.
        // N - Reset.
        // H - Set if carry from bit 11.
        // C - Set if carry from bit 15.
        
        lr35902.NF.write(false)
        lr35902.HF.write(addHalfCarryProne(op1, op2: op2))
        lr35902.CF.write(addCarryProne(op1, op2: op2))
    }
    
}

//@todo special LR35902 ADD16 that affects flags differently: ADD SP, n
