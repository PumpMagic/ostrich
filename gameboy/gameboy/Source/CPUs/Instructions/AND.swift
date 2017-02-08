//
//  AND.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/13/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func and(_ v1: UInt8, _ v2: UInt8) -> UInt8 {
    return v1 & v2
}

/// AND an operand and overwrite it with the new value
private func andAndStore
    <T: Readable & Writeable, U: Readable>
    (_ op1: T, _ op2: U)
    -> (T.ReadType, U.ReadType, T.WriteType)
    where T.ReadType == U.ReadType, T.ReadType == T.WriteType, T.ReadType == UInt8
{
    let op1v = op1.read()
    let op2v = op2.read()
    let result = and(op1v, op2v)
    op1.write(result)
    
    return (op1v, op2v, result)
}


/// Bitwise AND between the accumulator and an 8-bit operand; result gets stored in the accumulator
struct AND
    <T: Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == UInt8
{
    let op: T
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: Z80) {
        let (op1v, op2v, result) = andAndStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(_ cpu: LR35902) {
        let (op1v, op2v, result) = andAndStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, op1: UInt8, op2: T.ReadType, result: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set.
        // N is reset.
        // C is reset.

        
        cpu.ZF.write(result == 0x00)
        cpu.HF.write(true)
        cpu.NF.write(false)
        cpu.CF.write(false)
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is reset if overflow; otherwise, it is reset.
        cpu.SF.write(numberIsNegative(result))
        cpu.PVF.write(parity(result))
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
    }
}
