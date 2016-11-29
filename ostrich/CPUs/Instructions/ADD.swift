//
//  ADD.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/31/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func add<T: Integer>(_ v1: T, _ v2: T) -> T {
    return v1 &+ v2
}

private func addAndStore
    <T: Readable & Writeable, U: Readable>
    (_ op1: T, _ op2: U)
    -> (T.ReadType, U.ReadType, T.WriteType)
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType: Integer
{
    let op1v = op1.read()
    let op2v = op2.read()
    let result = add(op1v, op2v)
    op1.write(result)
    
    return (op1v, op2v, result)
}

private func addAndStore
    <T: Readable & Writeable, U: Readable>
    (_ op1: T, _ op2: U, _ op3: Bool)
    -> (T.ReadType, U.ReadType, T.ReadType, T.WriteType)
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType: Integer
{
    let op1v = op1.read()
    let op2v = op2.read()
    let op3v: T.ReadType = op3 ? 1 : 0
    
    let result = add(op1v, add(op2v, op3v))
    op1.write(result)
    
    return (op1v, op2v, op3v, result)
}


/// Add two 8-bit operands; overwrite the first with the result
struct ADD8
    <T: Readable & Writeable & OperandType, U: Readable & OperandType>: Z80Instruction, LR35902Instruction
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType == UInt8
{
    let op1: T
    let op2: U
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: Z80) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(_ cpu: LR35902) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, op1: T.ReadType, op2: U.ReadType, result: T.ReadType)
    {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if carry from bit 3; otherwise, it is reset.
        // N is reset.
        // C is set if carry from bit 7; otherwise, it is reset.
        
        cpu.ZF.write(result == 0x00)
        cpu.HF.write(addHalfCarryProne(op1, op2))
        cpu.NF.write(false)
        cpu.CF.write(addCarryProne(op1, op2))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if overflow; otherwise, it is reset.
        cpu.SF.write(numberIsNegative(result))
        cpu.PVF.write(addOverflowOccurred(op1, op2, result: result))
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
    }
}

/// Add two 16-bit operands; overwrite the first with the result
struct ADD16
    <T: Readable & Writeable & OperandType, U: Readable & OperandType>: Z80Instruction, LR35902Instruction
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType == UInt16
{
    let op1: T
    let op2: U
    
    let cycleCount = 0
    
    
    func runOn(_ z80: Z80) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(z80, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(_ lr35902: LR35902) {
        let (op1v, op2v, result) = addAndStore(op1, op2)
        modifyFlags(lr35902, op1: op1v, op2: op2v, result: result)
    }
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, op1: T.ReadType, op2: U.ReadType, result: T.ReadType)
    {
        // Z is not affected.
        // H is set if carry from bit 11; otherwise, it is reset.
        // N is reset.
        // C is set if carry from bit 15; otherwise, it is reset.
        
        cpu.HF.write(addHalfCarryProne(op1, op2))
        cpu.NF.write(false)
        cpu.CF.write(addCarryProne(op1, op2))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
        
        // S is not affected.
        // P/V is not affected.
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, op1: T.ReadType, op2: U.ReadType, result: T.ReadType) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
    }
}

/// Add an immediate to the stack pointer
struct ADDSP: LR35902Instruction {
    let value: Int8
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: LR35902) {
        let op1v = cpu.SP.read()
        let op2v = value
        let resultOverflowed = Int(op1v) &+ Int(op2v)
        let result = Address(truncatingBitPattern: resultOverflowed)
        cpu.SP.write(result)
        modifyFlags(cpu, op1: op1v, op2: op2v)
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, op1: Address, op2: Int8) {
        // Z - Reset.
        // N - Reset.
        // H is set if carry from bit 11; otherwise, it is reset.
        // C is set if carry from bit 15; otherwise, it is reset.
        cpu.ZF.write(false)
        cpu.NF.write(false)
        cpu.HF.write(addHalfCarryProne(op1, op2))
        cpu.CF.write(addCarryProne(op1, op2))
    }
}


struct ADC8
    <T: Readable & Writeable & OperandType, U: Readable & OperandType>: Z80Instruction, LR35902Instruction
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType == UInt8
{
    let op1: T
    let op2: U
    
    let cycleCount = 0
    
    // A ← A + s + CY
    func runOn(_ cpu: Z80) {
        let (op1v, op2v, op3v, result) = addAndStore(op1, op2, cpu.CF.read())
        modifyFlags(cpu, op1: op1v, op2: op2v, op3: op3v, result: result)
    }
    
    func runOn(_ cpu: LR35902) {
        let (op1v, op2v, op3v, result) = addAndStore(op1, op2, cpu.CF.read())
        modifyFlags(cpu, op1: op1v, op2: op2v, op3: op3v, result: result)
    }
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, op1: T.ReadType, op2: U.ReadType, op3: UInt8, result: T.ReadType)
    {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if carry from bit 3; otherwise, it is reset.
        // N is reset.
        // C is set if carry from bit 7: otherwise, it is reset.
        
        cpu.ZF.write(result == 0x00)
        cpu.HF.write(addHalfCarryProne(op1, op2, op3))
        cpu.NF.write(false)
        cpu.CF.write(addCarryProne(op1, op2, op3))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, op1: T.ReadType, op2: U.ReadType, op3: UInt8, result: T.ReadType) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, op3: op3, result: result)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if overflow; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(result))
        cpu.PVF.write(addOverflowOccurred(op1, op2, result: result))
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, op1: T.ReadType, op2: U.ReadType, op3: UInt8, result: T.ReadType) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, op3: op3, result: result)
    }
}
