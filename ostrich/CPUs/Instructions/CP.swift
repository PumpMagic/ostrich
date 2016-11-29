//
//  SUB.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/13/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Subtract from the accumulator an 8-bit operand and modify flags accordingly, discarding the result
struct CP
    <T: Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == UInt8
{
    let op: T
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: Z80) {
        let (op1v, op2v, result) = subWithoutStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    func runOn(_ cpu: LR35902) {
        let (op1v, op2v, result) = subWithoutStore(cpu.A, op)
        modifyFlags(cpu, op1: op1v, op2: op2v, result: result)
    }
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, op1: UInt8, op2: T.ReadType, result: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if borrow from bit 4; otherwise, it is reset.
        // N is set.
        // C is set if borrow; otherwise, it is reset
        
        cpu.ZF.write(result == 0x00)
        cpu.HF.write(subHalfBorrowProne(op1, op2))
        cpu.NF.write(true)
        cpu.CF.write(subBorrowProne(op1, op2))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if overflow; otherwise, it is reset.
        cpu.SF.write(numberIsNegative(result))
        cpu.PVF.write(subOverflowOccurred(op1, op2: op2, result: result))
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, op1: UInt8, op2: T.ReadType, result: UInt8) {
        modifyCommonFlags(cpu, op1: op1, op2: op2, result: result)
    }
}
