//
//  RLC.swift
//  ostrichframework
//
//  Created by Ryan Conway on 3/31/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Left rotate with carry
struct RLC<T: Writeable & Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == T.WriteType, T.ReadType == UInt8
{
    let op: T
    
    let cycleCount = 0
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) -> (UInt8, UInt8) {
        let oldValue = op.read()
        let newValue = rotateLeft(oldValue)
        
        op.write(newValue)
        
        return (oldValue, newValue)
    }
    
    func runOn(_ cpu: Z80) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(_ cpu: LR35902) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, oldValue: UInt8, newValue: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is reset.
        // N is reset.
        // C is data from bit 7 of source register.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 7))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if parity even; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(parity(newValue))
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
}

/// Left rotate with carry A
struct RLCA: Z80Instruction, LR35902Instruction {
    let cycleCount = 0
    
    func runOn(_ cpu: Z80) {
        let oldA = cpu.A.read()
        
        cpu.A.write(rotateLeft(oldA))
        modifyFlags(cpu, oldValue: oldA)
    }
    
    func runOn(_ cpu: LR35902) {
        let oldA = cpu.A.read()
        
        cpu.A.write(rotateLeft(oldA))
        modifyFlags(cpu, oldValue: oldA)
    }
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, oldValue: UInt8) {
        // Z is affected differently!
        // H is reset.
        // N is reset.
        // C is data from bit 7 of Accumulator.
        
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 7))
    }
    
    func modifyFlags(_ cpu: Z80, oldValue: UInt8) {
        // Z is not affected.
        
        modifyCommonFlags(cpu, oldValue: oldValue)
        
        // S is not affected.
        // P/V is not affected.
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, oldValue: UInt8) {
        // The GB CPU manual says Z is set if the result is 0.
        // The BSNES core always resets Z.
        // We go with the BSNES core.
        
        cpu.ZF.write(false)
        
        modifyCommonFlags(cpu, oldValue: oldValue)
    }
}


/// Left rotate through carry (9-bit rotate)
struct RL<T: Writeable & Readable & OperandType>: Z80Instruction, LR35902Instruction where T.ReadType == T.WriteType, T.ReadType == UInt8 {
    let op: T
    
    let cycleCount = 0
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) -> (UInt8, UInt8) {
        let oldValue = op.read()
        var newValue = shiftLeft(oldValue)
        if cpu.CF.read() {
            newValue = setBit(newValue, bit: 0)
        }
        
        op.write(newValue)
        
        return (oldValue, newValue)
    }
    
    func runOn(_ cpu: Z80) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(_ cpu: LR35902) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, oldValue: UInt8, newValue: UInt8) {
        // Z is set if result is 0; otherwise, it is reset.
        // H is reset.
        // N is reset.
        // C is data from bit 7 of source register.
        
        cpu.ZF.write(newValue == 0x00)
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 7))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is set if result is negative; otherwise, it is reset.
        // P/V is set if parity even; otherwise, it is reset.
        
        cpu.SF.write(numberIsNegative(newValue))
        cpu.PVF.write(parity(newValue))
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
}


/// Left rotate A through carry (9-bit rotate)
struct RLA: Z80Instruction, LR35902Instruction {
    let cycleCount = 0
    
    
    fileprivate func runCommon(_ cpu: Intel8080Like) -> (UInt8, UInt8) {
        let oldValue = cpu.A.read()
        var newValue = shiftLeft(oldValue)
        if cpu.CF.read() {
            newValue = setBit(newValue, bit: 0)
        }
        
        cpu.A.write(newValue)
        
        return (oldValue, newValue)
    }
    
    func runOn(_ cpu: Z80) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    func runOn(_ cpu: LR35902) {
        let (oldValue, newValue) = runCommon(cpu)
        
        modifyFlags(cpu, oldValue: oldValue, newValue: newValue)
    }
    
    
    fileprivate func modifyCommonFlags(_ cpu: Intel8080Like, oldValue: UInt8, newValue: UInt8) {
        // Z is affected differently!
        // H is reset.
        // N is reset.
        // C is data from bit 7 of Accumulator
        
        cpu.HF.write(false)
        cpu.NF.write(false)
        cpu.CF.write(bitIsHigh(oldValue, bit: 7))
    }
    
    fileprivate func modifyFlags(_ cpu: Z80, oldValue: UInt8, newValue: UInt8) {
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        
        // S is not affected.
        // P/V is not affected.
        // Z is not affected.
    }
    
    fileprivate func modifyFlags(_ cpu: LR35902, oldValue: UInt8, newValue: UInt8) {
        // The GB CPU manual says Z is set if the result is 0.
        // The BSNES core always resets Z.
        // We go with the BSNES core.
        
        modifyCommonFlags(cpu, oldValue: oldValue, newValue: newValue)
        cpu.ZF.write(false)
    }
}
