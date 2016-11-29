//
//  LD.swift
//  ostrich
//
//  Created by Ryan Conway on 3/27/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Load: store an operand in another operand.
struct LD
    <T: Writeable & OperandType,
    U: Readable & OperandType>: Z80Instruction, LR35902Instruction
    where T.WriteType == U.ReadType
{
    let dest: T
    let src: U
    
    let cycleCount = 0
    
    fileprivate func load() {
        dest.write(src.read())
    }
    
    func runOn(_ cpu: Z80) {
        load()
    }
    
    func runOn(_ cpu: LR35902) {
        load()
    }
}


// Special Z80 instructions
/// A special load-increment-increment-decrement, used to copy arrays or something
struct LDI_Z80: Z80Instruction {
    let cycleCount = 0
    
    func runOn(_ cpu: Z80) {
        cpu.DE.asPointerOn(cpu.bus).write(cpu.HL.asPointerOn(cpu.bus).read())
        incAndStore(cpu.DE)
        incAndStore(cpu.HL)
        decAndStore(cpu.BC)
        
        modifyFlags(cpu)
    }
    
    func modifyFlags(_ cpu: Z80) {
        // S is not affected.
        // Z is not affected.
        // H is reset.
        // P/V is set if BC – 1 ≠ 0; otherwise, it is reset.
        // N is reset.
        // C is not affected.
        
        let newBC = cpu.BC.read()
        
        cpu.HF.write(false)
        cpu.PVF.write(newBC != 0x00)
        cpu.NF.write(false)
    }
}


// Special LR35902 instructions
// LD A, ($FF00+C)
/// Load into A whatever's at (0xFF00 + C)
// Note that C is treated as unsigned here!
struct LDAC: LR35902Instruction {
    let cycleCount = 0
    
    func runOn(_ cpu: LR35902) {
        cpu.A.write(PseudoPointer8(base: 0xFF00, offset: cpu.C, bus: cpu.bus).read())
    }
}

// LD ($FF00+C), A
/// Load A into whatever's at (0xFF00 + C)
// Note that C is treated as unsigned here!
struct LDCA: LR35902Instruction {
    let cycleCount = 0
    
    func runOn(_ cpu: LR35902) {
        PseudoPointer8(base: 0xFF00, offset: cpu.C, bus: cpu.bus).write(cpu.A.read())
    }
}

// LD A, ($FF00+n)
// Note that n is unsigned here!
struct LDHAN: LR35902Instruction {
    let offset: UInt8
    
    let cycleCount = 0
    
    func runOn(_ cpu: LR35902) {
        cpu.A.write(PseudoPointer8(base: 0xFF00, offset: Immediate8(val: offset), bus: cpu.bus).read())
    }
}

// LD ($FF00+n), A
// Note that n is unsigned here!
struct LDHNA: LR35902Instruction {
    let offset: UInt8
    
    let cycleCount = 0
    
    func runOn(_ cpu: LR35902) {
        PseudoPointer8(base: 0xFF00, offset: Immediate8(val: offset), bus: cpu.bus).write(cpu.A.read())
    }
}

// LD HL, SP+n
struct LDHLSP: LR35902Instruction {
    let offset: Int8
    
    let cycleCount = 0
    
    func runOn(_ cpu: LR35902) {
        let sp = cpu.SP.read()
        let n = offset
        
        cpu.HL.write(UInt16(Int(sp) + n))
    }
    
    //@todo is this done right? what resource talks about how these flags are set?
    fileprivate func modifyFlags(_ cpu: LR35902, sp: UInt16, n: Int8) {
        cpu.ZF.write(false)
        cpu.NF.write(false)
        cpu.HF.write(addHalfCarryProne(sp, n))
        cpu.CF.write(addCarryProne(sp, n))
    }
}

enum LDDIDirection {
    case intoPointer
    case outOfPointer
}

/// Load and decrement: store whatever a dereferenceable points to into something else, or vice versa, then
/// decrement the dereferenceable
struct LDD_LR
    <T: Readable & Writeable & CanActAsPointer & OperandType,
    U: Readable & Writeable & OperandType>: LR35902Instruction
    where T.ReadType == Address, U.ReadType == UInt8, T.WriteType == T.ReadType, U.WriteType == U.ReadType
{
    let pointable: T
    let other: U
    let direction: LDDIDirection
    
    let cycleCount = 0
    
    func runOn(_ cpu: LR35902) {
        switch direction {
        case .intoPointer:
            pointable.storeInLocation(cpu.bus, val: other.read())
        case .outOfPointer:
            other.write(pointable.dereferenceOn(cpu.bus))
        }
        
        pointable.write(dec(pointable.read()))
    }
}

/// Load and increment: store whatever a dereferenceable points to into something else, or vice versa, then
/// increment the dereferenceable
struct LDI_LR
    <T: Readable & Writeable & CanActAsPointer & OperandType,
    U: Readable & Writeable & OperandType>: LR35902Instruction
    where T.ReadType == Address, U.ReadType == UInt8, T.WriteType == T.ReadType, U.WriteType == U.ReadType
{
    let pointable: T
    let other: U
    let direction: LDDIDirection
    
    let cycleCount = 0
    
    func runOn(_ cpu: LR35902) {
        switch direction {
        case .intoPointer:
            pointable.storeInLocation(cpu.bus, val: other.read())
        case .outOfPointer:
            other.write(pointable.dereferenceOn(cpu.bus))
        }
        
        pointable.write(inc(pointable.read()))
    }
}
