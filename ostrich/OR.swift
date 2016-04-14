//
//  OR.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/13/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func or(v1: UInt8, _ v2: UInt8) -> UInt8 {
    return v1 | v2
}

/// OR an operand and overwrite it with the new value
private func orAndStore
    <T: protocol<Readable, Writeable>, U: Readable
    where T.ReadType == U.ReadType, T.ReadType == T.WriteType, T.ReadType == UInt8>
    (op1: T, _ op2: U)
    -> (T.ReadType, U.ReadType, T.WriteType)
{
    let op1v = op1.read()
    let op2v = op2.read()
    let result = or(op1v, op2v)
    op1.write(result)
    
    return (op1v, op2v, result)
}


/// Bitwise OR between the accumulator and an 8-bit operand; result gets stored in the accumulator
struct OR
    <T: protocol<Readable, OperandType> where T.ReadType == UInt8>: Z80Instruction, LR35902Instruction
{
    let op: T
    
    let cycleCount = 0
    
    
    func runOn(cpu: Z80) {
        let (op1v, op2v, result) = orAndStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(cpu: LR35902) {
        let (op1v, op2v, result) = orAndStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    private func modifyCommonFlags(cpu: Intel8080Like, op1: UInt8, op2: T.ReadType, result: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set.
        // N is reset.
        // C is reset.
        
        
        cpu.ZF.write(result == 0x00)
        cpu.HF.write(true)
        cpu.NF.write(false)
        cpu.CF.write(false)
    }
    
    private func modifyFlags(cpu: Z80, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is reset if overflow; otherwise, it is reset.
        cpu.SF.write(numberIsNegative(result))
        cpu.PVF.write(parity(result))
    }
    
    private func modifyFlags(cpu: LR35902, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
    }
}