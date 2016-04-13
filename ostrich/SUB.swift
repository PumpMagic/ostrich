//
//  SUB.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/31/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


private func sub<T: IntegerType>(v1: T, _ v2: T) -> T {
    return v1 &- v2
}

private func subAndStore
    <T: protocol<Readable, Writeable>, U: Readable
    where T.WriteType == U.ReadType, T.ReadType == T.WriteType, T.ReadType: IntegerType>
    (op1: T, _ op2: U)
    -> (T.ReadType, U.ReadType, T.WriteType)
{
    let op1v = op1.read()
    let op2v = op2.read()
    let result = sub(op1v, op2v)
    op1.write(result)
    
    return (op1v, op2v, result)
}


/// Subtract from the accumulator an 8-bit operand; overwrite the accumulator with the result
struct SUB
    <T: protocol<Readable, OperandType> where T.ReadType == UInt8>: Z80Instruction, LR35902Instruction
{
    let op: T
    
    let cycleCount = 0
    
    
    func runOn(cpu: Z80) {
        let (op1v, op2v, result) = subAndStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(cpu: LR35902) {
        let (op1v, op2v, result) = subAndStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    private func modifyCommonFlags(cpu: Intel8080Like, op1: UInt8, op2: T.ReadType, result: UInt8)
    {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if borrow from bit 4; otherwise, it is reset.
        // N is set.
        // C is set if borrow; otherwise, it is reset
        
        cpu.ZF.write(result == 0x00)
        cpu.HF.write(subHalfBorrowProne(op1, op2))
        cpu.NF.write(false)
        cpu.CF.write(subBorrowProne(op1, op2))
    }
    
    private func modifyFlags(cpu: Z80, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if overflow; otherwise, it is reset.
        cpu.SF.write(numberIsNegative(result))
        cpu.PVF.write(subOverflowOccurred(op1, op2: op2, result: result))
    }
    
    private func modifyFlags(cpu: LR35902, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
    }
}