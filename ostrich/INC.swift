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


func inc<T: IntegerType>(num: T) -> T {
    return num &+ 1
}

/// Decrement an operand and overwrite it with the new value
/// Returns (oldValue, newValue)
func incAndStore<T: protocol<Readable, Writeable> where T.ReadType == T.WriteType, T.ReadType: IntegerType>(op: T) -> (T.ReadType, T.WriteType)
{
    let oldValue = op.read()
    let newValue = inc(oldValue)
    op.write(newValue)
    
    return (oldValue, newValue)
}


/// Increment an 8-bit operand
struct INC8<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.ReadType == UInt8>: Z80Instruction, LR35902Instruction {
    let operand: T
    
    let cycleCount = 0
    
    
    func runOn(cpu: Z80) {
        let (oldValue, newValue) = incAndStore(operand)
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(cpu: LR35902) {
        let (oldValue, newValue) = incAndStore(operand)
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    private func modifyCommonFlags(cpu: Intel8080Like, oldValue: T.ReadType, newValue: T.ReadType) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is set if carry from bit 3; otherwise, it is reset.
        // N is reset.
        // C is not affected.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.HF.write(oldValue == 0x0F)
        cpu.NF.write(false)
    }
    
    func modifyFlags(cpu: Z80, oldValue: T.ReadType, newValue: T.ReadType) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if r was 7Fh before operation; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(oldValue == 0x7F)
    }
    
    private func modifyFlags(cpu: LR35902, oldValue: T.ReadType, newValue: T.ReadType) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
}

/// Increment a 16-bit operand
struct INC16<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.ReadType == UInt16>: Z80Instruction, LR35902Instruction {
    let operand: T
    
    let cycleCount = 0
    
    func runOn(cpu: Z80) {
        incAndStore(operand)
    }
    
    func runOn(cpu: LR35902) {
        incAndStore(operand)
    }
}