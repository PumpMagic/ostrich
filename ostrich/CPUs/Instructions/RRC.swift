//
//  RRC.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/31/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Right rotate, copying into carry
struct RRC<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.ReadType == UInt8>: Z80Instruction, LR35902Instruction
{
    let op: T
    
    let cycleCount = 0
    
    
    private func runCommon(cpu: Intel8080Like) -> (UInt8, UInt8) {
        let oldValue = op.read()
        let newValue = rotateRight(oldValue)
        
        op.write(newValue)
        
        return (oldValue, newValue)
    }
    
    func runOn(cpu: Z80) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(cpu: LR35902) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    
    private func modifyCommonFlags(cpu: Intel8080Like, oldValue: UInt8, newValue: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is reset.
        // N is reset.
        // C is data from bit 0 of source register.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 0))
    }
    
    private func modifyFlags(cpu: Z80, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if parity even; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(parity(newValue))
    }
    
    private func modifyFlags(cpu: LR35902, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
}

/// Right rotate A, copying into carry
//@todo model this after RRC
struct RRCA: Z80Instruction, LR35902Instruction {
    let cycleCount = 0
    
    func runOn(cpu: Z80) {
        let oldA = cpu.A.read()
        
        cpu.A.write(rotateRight(oldA))
        modifyFlags(cpu, oldValue: oldA)
    }
    
    func runOn(cpu: LR35902) {
        let oldA = cpu.A.read()
        
        cpu.A.write(rotateRight(oldA))
        modifyFlags(cpu, oldValue: oldA)
    }
    
    private func modifyCommonFlags(cpu: Intel8080Like, oldValue: UInt8) {
        // Z is affected differently!
        // H is reset.
        // N is reset.
        // C is data from bit 0 of Accumulator.
        
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 0))
    }
    
    func modifyFlags(cpu: Z80, oldValue: UInt8) {
        // Z is not affected.
        
        modifyCommonFlags(cpu, oldValue: oldValue)
        
        // S is not affected.
        // P/V is not affected.
    }
    
    private func modifyFlags(cpu: LR35902, oldValue: UInt8) {
        // The GB CPU manual says Z is set if the result is 0.
        // The BSNES core always resets Z.
        // We go with the BSNES core.
        
        cpu.ZF.write(false)
        
        modifyCommonFlags(cpu, oldValue: oldValue)
    }
}

/// Right rotate through carry (9-bit rotate)
struct RR<T: protocol<Writeable, Readable, OperandType> where T.ReadType == T.WriteType, T.ReadType == UInt8>: Z80Instruction, LR35902Instruction {
    let op: T
    
    let cycleCount = 0
    
    
    private func runCommon(cpu: Intel8080Like) -> (UInt8, UInt8) {
        let oldValue = op.read()
        var newValue = logicalShiftRight(oldValue)
        if cpu.CF.read() {
            newValue = setBit(newValue, bit: 7)
        }
        
        op.write(newValue)
        
        return (oldValue, newValue)
    }
    
    func runOn(cpu: Z80) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(cpu: LR35902) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    
    private func modifyCommonFlags(cpu: Intel8080Like, oldValue: UInt8, newValue: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is reset.
        // N is reset.
        // C is data from bit 0 of source register.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 0))
    }
    
    private func modifyFlags(cpu: Z80, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if parity even; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(parity(newValue))
    }
    
    private func modifyFlags(cpu: LR35902, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
}

/// Special instruction for right rotate through carry (9-bit rotate) of A
struct RRA: Z80Instruction, LR35902Instruction {
    let cycleCount = 0
    
    
    private func runCommon(cpu: Intel8080Like) -> (UInt8, UInt8) {
        let oldValue = cpu.A.read()
        var newValue = logicalShiftRight(oldValue)
        if cpu.CF.read() {
            newValue = setBit(newValue, bit: 7)
        }
        
        cpu.A.write(newValue)
        
        return (oldValue, newValue)
    }
    
    func runOn(cpu: Z80) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(cpu: LR35902) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    
    private func modifyCommonFlags(cpu: Intel8080Like, oldValue: UInt8, newValue: UInt8) {
        // Z behaves differently!
        // H is reset.
        // N is reset.
        // C is data from bit 0 of source register.
        
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 0))
    }
    
    private func modifyFlags(cpu: Z80, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // Z is set if result is 0; otherwise, it is reset.
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if parity even; otherwise, it is reset.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(parity(newValue))
    }
    
    private func modifyFlags(cpu: LR35902, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // The GB CPU manual says Z is set if the result is 0.
        // The BSNES core always resets Z.
        // We go with the BSNES core.
        
        // N - Reset.
        // H - Reset.
        // C - Contains old bit 0 data.
        
        cpu.ZF.write(false)
    }
}