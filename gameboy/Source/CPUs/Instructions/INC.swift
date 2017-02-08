//
//  INC.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


// INC is split into 8-bit and 16-bit groups here because it only affects flags when working with
// 8-bit operands


func inc<T: Integer>(_ num: T) -> T {
    return num &+ 1
}

/// Decrement an operand and overwrite it with the new value
/// Returns (oldValue, newValue)
func incAndStore<T: Readable & Writeable>(_ op: T) -> (T.ReadType, T.WriteType) where T.ReadType == T.WriteType, T.ReadType: Integer
{
    let oldValue = op.read()
    let newValue = inc(oldValue)
    op.write(newValue)
    
    return (oldValue, newValue)
}


/// Increment an 8-bit operand
struct INC8<T: Writeable & Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == T.WriteType, T.ReadType == UInt8 {
    let operand: T
    
    let cycleCount = 0
    
    
    func runOn(_ cpu: Z80) {
        let (oldValue, newValue) = incAndStore(operand)
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(_ cpu: LR35902) {
        let (oldValue, newValue) = incAndStore(operand)
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, oldValue: T.ReadType, newValue: T.ReadType) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if carry from bit 3; otherwise, it is reset.
        // N is reset.
        // C is not affected.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.HF.write(newValue & 0x0F == 0x00)
        cpu.NF.write(false)
    }
    
    func modifyFlags(_ cpu: Z80, oldValue: T.ReadType, newValue: T.ReadType) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if r was 7Fh before operation; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(oldValue == 0x7F)
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, oldValue: T.ReadType, newValue: T.ReadType) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
}

/// Increment a 16-bit operand
struct INC16<T: Writeable & Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == T.WriteType, T.ReadType == UInt16 {
    let operand: T
    
    let cycleCount = 0
    
    func runOn(_ cpu: Z80) {
        incAndStore(operand)
    }
    
    func runOn(_ cpu: LR35902) {
        incAndStore(operand)
    }
}
