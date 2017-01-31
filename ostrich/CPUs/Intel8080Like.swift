//
//  8080Like.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/6/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


struct Intel8080InstructionContext {
    var lastInstructionWasDI: Bool
    var lastInstructionWasEI: Bool
}

enum FlipFlop {
    case enabled
    case disabled
}

/// Everything in common between the Z80 and the LR35902.
protocol Intel8080Like {
    var A: Register8 { get }
    var B: Register8 { get }
    var C: Register8 { get }
    var D: Register8 { get }
    var E: Register8 { get }
    var F: Register8 { get }
    var H: Register8 { get }
    var L: Register8 { get }
    
    var I: Register8 { get }
    var R: Register8 { get }
    
    var AF: Register16Computed { get }
    var BC: Register16Computed { get }
    var DE: Register16Computed { get }
    var HL: Register16Computed { get }
    
    var SP: Register16 { get }
    var PC: Register16 { get }
    
    var ZF: Flag { get }
    var NF: Flag { get }
    var HF: Flag { get }
    var CF: Flag { get }
    
    var IFF1: FlipFlop { get }
    var IFF2: FlipFlop { get }
    
    var bus: DataBus { get }
    
    func push(_ val: UInt16)
    func pop() -> UInt16
}

extension Intel8080Like {
    /// Push a two-byte value onto the stack.
    /// Adjusts the stack pointer accordingly.
    func push(_ val: UInt16) {
        let oldAddr = self.SP.read()
        let newAddr = oldAddr - 2
        
        self.SP.write(newAddr)
        
        self.bus.write16(val, to: newAddr)
    }
    
    func pop() -> UInt16 {
        let addr = self.SP.read()
        let val = self.bus.read16(addr)
        
        self.SP.write(addr + 2)
        return val
    }
    
    func fetchInstructionCommon() -> Instruction? {
        let firstByte = bus.read(PC.read())
        
        var instruction: Z80Instruction? = nil
        var instructionLength: UInt16 = 1
        
        switch firstByte {
        case 0x00:
            // NOP
            instruction = NOP()
            instructionLength = 1
        
        case 0x01:
            // LD BC, nn
            let val = bus.read16(PC.read()+1)
            instruction = LD(dest: self.BC, src: Immediate16(val: val))
            instructionLength = 3
        
        case 0x02:
            // LD (BC), A
            instruction = LD(dest: self.BC.asPointerOn(self.bus), src: self.A)
            instructionLength = 1
        
        case 0x03:
            // INC BC
            instruction = INC16(operand: self.BC)
            instructionLength = 1
        
        case 0x04:
            // INC B
            instruction = INC8(operand: self.B)
            instructionLength = 1
        
        case 0x05:
            // DEC B
            instruction = DEC8(operand: self.B)
            instructionLength = 1
        
        case 0x06:
            // LD B, n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.B, src: Immediate8(val: val))
            instructionLength = 2
        
        case 0x07:
            // RLCA
            instruction = RLCA()
            instructionLength = 1
            
        case 0x09:
            // ADD HL, BC
            instruction = ADD16(op1: self.HL, op2: self.BC)
            instructionLength = 1
            
        case 0x0A:
            // LD A, (BC)
            instruction = LD(dest: self.A, src: self.BC.asPointerOn(bus))
            instructionLength = 1
            
        case 0x0B:
            // DEC BC
            instruction = DEC16(operand: self.BC)
            instructionLength = 1
            
        case 0x0C:
            // INC C
            instruction = INC8(operand: self.C)
            instructionLength = 1
            
        case 0x0D:
            // DEC C
            instruction = DEC8(operand: self.C)
            instructionLength = 1
            
        case 0x0E:
            // LD C, n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.C, src: Immediate8(val: val))
            instructionLength = 2
            
        case 0x0F:
            // RRCA
            instruction = RRCA()
            instructionLength = 1
             
 
 
        case 0x11:
            // LD DE, nn
            let val = bus.read16(PC.read()+1)
            instruction = LD(dest: self.DE, src: Immediate16(val: val))
            instructionLength = 3
            
        case 0x12:
            // LD (DE), A
            instruction = LD(dest: self.DE.asPointerOn(self.bus), src: self.A)
            instructionLength = 1
            
        case 0x13:
            // INC DE
            instruction = INC16(operand: self.DE)
            instructionLength = 1
            
        case 0x14:
            // INC D
            instruction = INC8(operand: self.D)
            instructionLength = 1
            
        case 0x15:
            // DEC D
            instruction = DEC8(operand: self.D)
            instructionLength = 1
            
        case 0x16:
            // LD D, n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.D, src: Immediate8(val: val))
            instructionLength = 2
            
        case 0x17:
            // RLA
            instruction = RLA()
            instructionLength = 1
            
        case 0x18:
            // JR n
            let displacement = Int8(bitPattern: bus.read(PC.read()+1))
            instruction = JR(condition: nil, displacementMinusTwo: displacement)
            instructionLength = 2
            
        case 0x19:
            // ADD HL, DE
            instruction = ADD16(op1: self.HL, op2: self.DE)
            instructionLength = 1
            
        case 0x1A:
            // LD A, (DE)
            instruction = LD(dest: self.A, src: self.DE.asPointerOn(bus))
            instructionLength = 1
            
        case 0x1B:
            // DEC DE
            instruction = DEC16(operand: self.DE)
            instructionLength = 1
            
        case 0x1C:
            // INC E
            instruction = INC8(operand: self.E)
            instructionLength = 1
            
        case 0x1D:
            // DEC E
            instruction = DEC8(operand: self.E)
            instructionLength = 1
            
        case 0x1E:
            // LD E, n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.E, src: Immediate8(val: val))
            instructionLength = 2
            
        case 0x1F:
            // RRCA
            instruction = RRCA()
            instructionLength = 1
 
 
 
            
        case 0x20:
            // JR NZ n
            let displacement = Int8(bitPattern: bus.read(PC.read()+1))
            instruction = JR(condition: Condition(flag: self.ZF, target: false), displacementMinusTwo: displacement)
            instructionLength = 2
            
        case 0x21:
            // LD HL, nn
            let val = bus.read16(PC.read()+1)
            instruction = LD(dest: self.HL, src: Immediate16(val: val))
            instructionLength = 3
            
        case 0x23:
            // INC HL
            instruction = INC16(operand: self.HL)
            instructionLength = 1
            
        case 0x24:
            // INC H
            instruction = INC8(operand: self.H)
            instructionLength = 1
            
        case 0x25:
            // DEC H
            instruction = DEC8(operand: self.H)
            instructionLength = 1
            
        case 0x26:
            // LD H, n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.H, src: Immediate8(val: val))
            instructionLength = 2
            
        case 0x28:
            // JR Z n
            let displacement = Int8(bitPattern: bus.read(PC.read()+1))
            instruction = JR(condition: Condition(flag: self.ZF, target: true), displacementMinusTwo: displacement)
            instructionLength = 2
            
        case 0x29:
            // ADD HL, HL
            instruction = ADD16(op1: self.HL, op2: self.HL)
            instructionLength = 1
            
        case 0x2B:
            // DEC HL
            instruction = DEC16(operand: self.HL)
            instructionLength = 1
            
        case 0x2C:
            // INC L
            instruction = INC8(operand: self.L)
            instructionLength = 1
            
        case 0x2D:
            // DEC L
            instruction = DEC8(operand: self.L)
            instructionLength = 1
            
        case 0x2E:
            // LD L, n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.L, src: Immediate8(val: val))
            instructionLength = 2
            
        case 0x2F:
            // CPL
            instruction = CPL()
            instructionLength = 1
            
        case 0x30:
            // JR NC n
            let displacement = Int8(bus.read(PC.read()+1))
            instruction = JR(condition: Condition(flag: self.CF, target: false), displacementMinusTwo: displacement)
            instructionLength = 2
            
        case 0x31:
            // LD SP, nn
            let val = bus.read16(PC.read()+1)
            instruction = LD(dest: self.SP, src: Immediate16(val: val))
            instructionLength = 3
            
        case 0x33:
            // INC SP
            instruction = INC16(operand: self.SP)
            instructionLength = 1
            
        case 0x34:
            // INC (HL)
            instruction = INC8(operand: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x35:
            // DEC (HL)
            instruction = DEC8(operand: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x36:
            // LD (HL), n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.HL.asPointerOn(bus), src: Immediate8(val: val))
            instructionLength = 2
            
        case 0x37:
            // SCF
            instruction = SCF()
            instructionLength = 1
            
        case 0x38:
            // JR C n
            let displacement = Int8(bitPattern: bus.read(PC.read()+1))
            instruction = JR(condition: Condition(flag: self.CF, target: true), displacementMinusTwo: displacement)
            instructionLength = 2
            
        case 0x39:
            // ADD HL, SP
            instruction = ADD16(op1: self.HL, op2: self.SP)
            instructionLength = 1
            
        case 0x3B:
            // DEC SP
            instruction = DEC16(operand: self.SP)
            instructionLength = 1
            
        case 0x3C:
            // INC A
            instruction = INC8(operand: self.A)
            instructionLength = 1
            
        case 0x3D:
            // DEC A
            instruction = DEC8(operand: self.A)
            instructionLength = 1
            
        case 0x3E:
            // LD A, n
            let val = bus.read(PC.read()+1)
            instruction = LD(dest: self.A, src: Immediate8(val: val))
            instructionLength = 2
            
        case 0x3F:
            // CCF
            instruction = CCF()
            instructionLength = 1
            
        case 0x40:
            // LD B, B
            instruction = LD(dest: self.B, src: self.B)
            instructionLength = 1
            
        case 0x41:
            // LD B, C
            instruction = LD(dest: self.B, src: self.C)
            instructionLength = 1
            
        case 0x42:
            // LD B, D
            instruction = LD(dest: self.B, src: self.D)
            instructionLength = 1
            
        case 0x43:
            // LD B, E
            instruction = LD(dest: self.B, src: self.E)
            instructionLength = 1
            
        case 0x44:
            // LD B, H
            instruction = LD(dest: self.B, src: self.H)
            instructionLength = 1
            
        case 0x45:
            // LD B, L
            instruction = LD(dest: self.B, src: self.L)
            instructionLength = 1
            
        case 0x46:
            // LD B, (HL)
            instruction = LD(dest: self.B, src: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x47:
            // LD B, A
            instruction = LD(dest: self.B, src: self.A)
            instructionLength = 1
            
        case 0x48:
            // LD C, B
            instruction = LD(dest: self.C, src: self.B)
            instructionLength = 1
            
        case 0x49:
            // LD C, C
            instruction = LD(dest: self.C, src: self.C)
            instructionLength = 1
            
        case 0x4A:
            // LD C, D
            instruction = LD(dest: self.C, src: self.D)
            instructionLength = 1
            
        case 0x4B:
            // LD C, E
            instruction = LD(dest: self.C, src: self.E)
            instructionLength = 1
            
        case 0x4C:
            // LD C, H
            instruction = LD(dest: self.C, src: self.H)
            instructionLength = 1
            
        case 0x4D:
            // LD C, L
            instruction = LD(dest: self.C, src: self.L)
            instructionLength = 1
            
        case 0x4E:
            // LD C, (HL)
            instruction = LD(dest: self.C, src: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x4F:
            // LD C, A
            instruction = LD(dest: self.C, src: self.A)
            instructionLength = 1
            
        case 0x50:
            // LD D, B
            instruction = LD(dest: self.D, src: self.B)
            instructionLength = 1
            
        case 0x51:
            // LD D, C
            instruction = LD(dest: self.D, src: self.C)
            instructionLength = 1
            
        case 0x52:
            // LD D, D
            instruction = LD(dest: self.D, src: self.D)
            instructionLength = 1
            
        case 0x53:
            // LD D, E
            instruction = LD(dest: self.D, src: self.E)
            instructionLength = 1
            
        case 0x54:
            // LD D, H
            instruction = LD(dest: self.D, src: self.H)
            instructionLength = 1
            
        case 0x55:
            // LD D, L
            instruction = LD(dest: self.D, src: self.L)
            instructionLength = 1
            
        case 0x56:
            // LD D, (HL)
            instruction = LD(dest: self.D, src: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x57:
            // LD D, A
            instruction = LD(dest: self.D, src: self.A)
            instructionLength = 1
            
        case 0x58:
            // LD E, B
            instruction = LD(dest: self.E, src: self.B)
            instructionLength = 1
            
        case 0x59:
            // LD E, C
            instruction = LD(dest: self.E, src: self.C)
            instructionLength = 1
            
        case 0x5A:
            // LD E, D
            instruction = LD(dest: self.E, src: self.D)
            instructionLength = 1
            
        case 0x5B:
            // LD E, E
            instruction = LD(dest: self.E, src: self.E)
            instructionLength = 1
            
        case 0x5C:
            // LD E, H
            instruction = LD(dest: self.E, src: self.H)
            instructionLength = 1
            
        case 0x5D:
            // LD E, L
            instruction = LD(dest: self.E, src: self.L)
            instructionLength = 1
            
        case 0x5E:
            // LD E, (HL)
            instruction = LD(dest: self.E, src: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x5F:
            // LD E, A
            instruction = LD(dest: self.E, src: self.A)
            instructionLength = 1
            
        case 0x60:
            // LD H, B
            instruction = LD(dest: self.H, src: self.B)
            instructionLength = 1
            
        case 0x61:
            // LD H, C
            instruction = LD(dest: self.H, src: self.C)
            instructionLength = 1
            
        case 0x62:
            // LD H, D
            instruction = LD(dest: self.H, src: self.D)
            instructionLength = 1
            
        case 0x63:
            // LD H, E
            instruction = LD(dest: self.H, src: self.E)
            instructionLength = 1
            
        case 0x64:
            // LD H, H
            instruction = LD(dest: self.H, src: self.H)
            instructionLength = 1
            
        case 0x65:
            // LD H, L
            instruction = LD(dest: self.H, src: self.L)
            instructionLength = 1
            
        case 0x66:
            // LD H, (HL)
            instruction = LD(dest: self.H, src: self.HL.asPointerOn(self.bus))
            instructionLength = 1
            
        case 0x67:
            // LD H, A
            instruction = LD(dest: self.H, src: self.A)
            instructionLength = 1
            
        case 0x68:
            // LD L, B
            instruction = LD(dest: self.L, src: self.B)
            instructionLength = 1
            
        case 0x69:
            // LD L, C
            instruction = LD(dest: self.L, src: self.C)
            instructionLength = 1
            
        case 0x6A:
            // LD L, D
            instruction = LD(dest: self.L, src: self.D)
            instructionLength = 1
            
        case 0x6B:
            // LD L, E
            instruction = LD(dest: self.L, src: self.E)
            instructionLength = 1
            
        case 0x6C:
            // LD L, H
            instruction = LD(dest: self.L, src: self.H)
            instructionLength = 1
            
        case 0x6D:
            // LD L, L
            instruction = LD(dest: self.L, src: self.L)
            instructionLength = 1
            
        case 0x6E:
            // LD L, (HL)
            instruction = LD(dest: self.L, src: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x6F:
            // LD L, A
            instruction = LD(dest: self.L, src: self.A)
            instructionLength = 1
            
        case 0x70:
            // LD (HL), B
            instruction = LD(dest: self.HL.asPointerOn(self.bus), src: self.B)
            instructionLength = 1
            
        case 0x71:
            // LD (HL), C
            instruction = LD(dest: self.HL.asPointerOn(self.bus), src: self.C)
            instructionLength = 1
            
        case 0x72:
            // LD (HL), D
            instruction = LD(dest: self.HL.asPointerOn(self.bus), src: self.D)
            instructionLength = 1
            
        case 0x73:
            // LD (HL), E
            instruction = LD(dest: self.HL.asPointerOn(self.bus), src: self.E)
            instructionLength = 1
            
        case 0x74:
            // LD (HL), H
            instruction = LD(dest: self.HL.asPointerOn(self.bus), src: self.H)
            instructionLength = 1
            
        case 0x75:
            // LD (HL), L
            instruction = LD(dest: self.HL.asPointerOn(self.bus), src: self.L)
            instructionLength = 1
            
        case 0x77:
            // LD (HL), A
            instruction = LD(dest: self.HL.asPointerOn(bus), src: self.A)
            instructionLength = 1
            
        case 0x78:
            // LD A, B
            instruction = LD(dest: self.A, src: self.B)
            instructionLength = 1
            
        case 0x79:
            // LD A, C
            instruction = LD(dest: self.A, src: self.C)
            instructionLength = 1
            
        case 0x7A:
            // LD A, D
            instruction = LD(dest: self.A, src: self.D)
            instructionLength = 1
            
        case 0x7B:
            // LD A, E
            instruction = LD(dest: self.A, src: self.E)
            instructionLength = 1
            
        case 0x7C:
            // LD A, H
            instruction = LD(dest: self.A, src: self.H)
            instructionLength = 1
            
        case 0x7D:
            // LD A, L
            instruction = LD(dest: self.A, src: self.L)
            instructionLength = 1
            
        case 0x7E:
            // LD A, (HL)
            instruction = LD(dest: self.A, src: self.HL.asPointerOn(bus))
            instructionLength = 1
            
        case 0x7F:
            // LD A, A
            instruction = LD(dest: self.A, src: self.A)
            instructionLength = 1
            
        case 0x80:
            // ADD A, B
            instruction = ADD8(op1: self.A, op2: self.B)
            instructionLength = 1
        case 0x81:
            // ADD A, C
            instruction = ADD8(op1: self.A, op2: self.C)
            instructionLength = 1
        case 0x82:
            // ADD A, D
            instruction = ADD8(op1: self.A, op2: self.D)
            instructionLength = 1
        case 0x83:
            // ADD A, E
            instruction = ADD8(op1: self.A, op2: self.E)
            instructionLength = 1
        case 0x84:
            // ADD A, H
            instruction = ADD8(op1: self.A, op2: self.H)
            instructionLength = 1
        case 0x85:
            // ADD A, L
            instruction = ADD8(op1: self.A, op2: self.L)
            instructionLength = 1
        case 0x86:
            // ADD A, (HL)
            instruction = ADD8(op1: self.A, op2: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0x87:
            // ADD A, A
            instruction = ADD8(op1: self.A, op2: self.A)
            instructionLength = 1
            
        case 0x88:
            // ADC A, B
            instruction = ADC8(op1: self.A, op2: self.B)
            instructionLength = 1
        case 0x89:
            // ADC A, C
            instruction = ADC8(op1: self.A, op2: self.C)
            instructionLength = 1
        case 0x8A:
            // ADC A, D
            instruction = ADC8(op1: self.A, op2: self.D)
            instructionLength = 1
        case 0x8B:
            // ADC A, E
            instruction = ADC8(op1: self.A, op2: self.E)
            instructionLength = 1
        case 0x8C:
            // ADC A, H
            instruction = ADC8(op1: self.A, op2: self.H)
            instructionLength = 1
        case 0x8D:
            // ADC A, L
            instruction = ADC8(op1: self.A, op2: self.L)
            instructionLength = 1
        case 0x8E:
            // ADC A, (HL)
            instruction = ADC8(op1: self.A, op2: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0x8F:
            // ADC A, A
            instruction = ADC8(op1: self.A, op2: self.A)
            instructionLength = 1

        case 0x90:
            // SUB B
            instruction = SUB(op: self.B)
            instructionLength = 1
        case 0x91:
            // SUB C
            instruction = SUB(op: self.C)
            instructionLength = 1
        case 0x92:
            // SUB D
            instruction = SUB(op: self.D)
            instructionLength = 1
        case 0x93:
            // SUB E
            instruction = SUB(op: self.E)
            instructionLength = 1
        case 0x94:
            // SUB H
            instruction = SUB(op: self.H)
            instructionLength = 1
        case 0x95:
            // SUB L
            instruction = SUB(op: self.L)
            instructionLength = 1
        case 0x96:
            // SUB (HL)
            instruction = SUB(op: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0x97:
            // SUB A
            instruction = SUB(op: self.A)
            instructionLength = 1
            
        case 0x98:
            // SBC B
            instruction = SBC(op: self.B)
            instructionLength = 1
        case 0x99:
            // SBC C
            instruction = SBC(op: self.C)
            instructionLength = 1
        case 0x9A:
            // SBC D
            instruction = SBC(op: self.D)
            instructionLength = 1
        case 0x9B:
            // SBC E
            instruction = SBC(op: self.E)
            instructionLength = 1
        case 0x9C:
            // SBC H
            instruction = SBC(op: self.H)
            instructionLength = 1
        case 0x9D:
            // SBC L
            instruction = SBC(op: self.L)
            instructionLength = 1
        case 0x9E:
            // SBC (HL)
            instruction = SBC(op: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0x9F:
            // SBC A
            instruction = SBC(op: self.A)
            instructionLength = 1
            
            
            
        case 0xA0:
            // AND B
            instruction = AND(op: self.B)
            instructionLength = 1
        case 0xA1:
            // AND C
            instruction = AND(op: self.C)
            instructionLength = 1
        case 0xA2:
            // AND D
            instruction = AND(op: self.D)
            instructionLength = 1
        case 0xA3:
            // AND E
            instruction = AND(op: self.E)
            instructionLength = 1
        case 0xA4:
            // AND H
            instruction = AND(op: self.H)
            instructionLength = 1
        case 0xA5:
            // AND L
            instruction = AND(op: self.L)
            instructionLength = 1
        case 0xA6:
            // AND (HL)
            instruction = AND(op: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0xA7:
            // AND A
            instruction = AND(op: self.A)
            instructionLength = 1
            
        case 0xA8:
            // XOR B
            instruction = XOR(op: self.B)
            instructionLength = 1
        case 0xA9:
            // XOR C
            instruction = XOR(op: self.C)
            instructionLength = 1
        case 0xAA:
            // XOR D
            instruction = XOR(op: self.D)
            instructionLength = 1
        case 0xAB:
            // XOR E
            instruction = XOR(op: self.E)
            instructionLength = 1
        case 0xAC:
            // XOR H
            instruction = XOR(op: self.H)
            instructionLength = 1
        case 0xAD:
            // XOR L
            instruction = XOR(op: self.L)
            instructionLength = 1
        case 0xAE:
            // XOR (HL)
            instruction = XOR(op: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0xAF:
            // XOR A
            instruction = XOR(op: self.A)
            instructionLength = 1
            
        case 0xB0:
            // OR B
            instruction = OR(op: self.B)
            instructionLength = 1
        case 0xB1:
            // OR C
            instruction = OR(op: self.C)
            instructionLength = 1
        case 0xB2:
            // OR D
            instruction = OR(op: self.D)
            instructionLength = 1
        case 0xB3:
            // OR E
            instruction = OR(op: self.E)
            instructionLength = 1
        case 0xB4:
            // OR H
            instruction = OR(op: self.H)
            instructionLength = 1
        case 0xB5:
            // OR L
            instruction = OR(op: self.L)
            instructionLength = 1
        case 0xB6:
            // OR (HL)
            instruction = OR(op: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0xB7:
            // OR A
            instruction = OR(op: self.A)
            instructionLength = 1
            
        case 0xB8:
            // CP B
            instruction = CP(op: self.B)
            instructionLength = 1
        case 0xB9:
            // CP C
            instruction = CP(op: self.C)
            instructionLength = 1
        case 0xBA:
            // CP D
            instruction = CP(op: self.D)
            instructionLength = 1
        case 0xBB:
            // CP E
            instruction = CP(op: self.E)
            instructionLength = 1
        case 0xBC:
            // CP H
            instruction = CP(op: self.H)
            instructionLength = 1
        case 0xBD:
            // CP L
            instruction = CP(op: self.L)
            instructionLength = 1
        case 0xBE:
            // CP (HL)
            instruction = CP(op: self.HL.asPointerOn(self.bus))
            instructionLength = 1
        case 0xBF:
            // CP A
            instruction = CP(op: self.A)
            instructionLength = 1
            
        case 0xC0:
            // RET nz
            instruction = RET(condition: Condition(flag: self.ZF, target: false))
            instructionLength = 1
            
        case 0xC1:
            // POP BC
            instruction = POP(operand: self.BC)
            instructionLength = 1
            
        case 0xC2:
            // JP nz, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.ZF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xC3:
            // JP nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: nil, dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xC4:
            // CALL NZ, nn
            let addr = bus.read16(PC.read()+1)
            instruction = CALL(condition: Condition(flag: self.ZF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xC5:
            // PUSH BC
            instruction = PUSH(operand: self.BC)
            instructionLength = 1
            
        case 0xC6:
            // ADD A, n
            let val = bus.read(PC.read()+1)
            instruction = ADD8(op1: self.A, op2: Immediate8(val: val))
            instructionLength = 2
            
        case 0xC8:
            // RET z
            instruction = RET(condition: Condition(flag: self.ZF, target: true))
            instructionLength = 1
            
        case 0xC9:
            // RET
            instruction = RET(condition: nil)
            instructionLength = 1
            
        case 0xCA:
            // JP z, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.ZF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xCC:
            // CALL Z, nn
            let addr = bus.read16(PC.read()+1)
            instruction = CALL(condition: Condition(flag: self.ZF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xCD:
            // CALL nn
            let addr = bus.read16(PC.read()+1)
            instruction = CALL(condition: nil, dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xD0:
            // RET nc
            instruction = RET(condition: Condition(flag: self.CF, target: false))
            instructionLength = 1
            
        case 0xD1:
            // POP DE
            instruction = POP(operand: self.DE)
            instructionLength = 1
            
        case 0xD2:
            // JP nc, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.CF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xD4:
            // CALL NC, nn
            let addr = bus.read16(PC.read()+1)
            instruction = CALL(condition: Condition(flag: self.CF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xD5:
            // PUSH DE
            instruction = PUSH(operand: self.DE)
            instructionLength = 1
            
        case 0xD6:
            // SUB n
            let val = bus.read(PC.read()+1)
            instruction = SUB(op: Immediate8(val: val))
            instructionLength = 2
            
        case 0xD8:
            // RET c
            instruction = RET(condition: Condition(flag: self.CF, target: true))
            instructionLength = 1
            
        case 0xDA:
            // JP c, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.CF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xDC:
            // CALL C, nn
            let addr = bus.read16(PC.read()+1)
            instruction = CALL(condition: Condition(flag: self.CF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xDF:
            // RST 0x18
            instruction = RST(restartAddress: 0x18)
            instructionLength = 1
            
        case 0xE1:
            // POP HL
            instruction = POP(operand: self.HL)
            instructionLength = 1
            
        case 0xE5:
            // PUSH HL
            instruction = PUSH(operand: self.HL)
            instructionLength = 1
            
        case 0xE6:
            // AND n
            let val = bus.read(PC.read()+1)
            instruction = AND(op: Immediate8(val: val))
            instructionLength = 2
            
        case 0xE9:
            // JP (HL)
            instruction = JP(condition: nil, dest: self.HL)
            instructionLength = 1
            
        case 0xF1:
            // POP AF
            instruction = POP(operand: self.AF)
            instructionLength = 1
            
        case 0xF3:
            // DI
            instruction = DI()
            instructionLength = 1
            
        case 0xF5:
            // PUSH AF
            instruction = PUSH(operand: self.AF)
            instructionLength = 1
            
        case 0xF6:
            // OR n
            let val = bus.read(PC.read()+1)
            instruction = OR(op: Immediate8(val: val))
            instructionLength = 2
            
        case 0xFB:
            // EI
            instruction = EI()
            instructionLength = 1
            
        case 0xFE:
            // CP n
            let subtrahend = bus.read(PC.read()+1)
            instruction = CP(op: Immediate8(val: subtrahend))
            instructionLength = 2
            
        case 0xCB:
            // bit instructions
            let secondByte = bus.read(PC.read()+1)
            switch secondByte {

            case 0x10:
                // RL B
                instruction = RL(op: self.B)
                instructionLength = 2
            case 0x11:
                // RL C
                instruction = RL(op: self.C)
                instructionLength = 2
            case 0x12:
                // RL D
                instruction = RL(op: self.D)
                instructionLength = 2
            case 0x13:
                // RL E
                instruction = RL(op: self.E)
                instructionLength = 2
            case 0x14:
                // RL H
                instruction = RL(op: self.H)
                instructionLength = 2
            case 0x15:
                // RL L
                instruction = RL(op: self.L)
                instructionLength = 2
            case 0x16:
                // RL (HL)
                instruction = RL(op: self.HL.asPointerOn(self.bus))
                instructionLength = 2
            case 0x17:
                // RL A
                instruction = RL(op: self.A)
                instructionLength = 2
                
            case 0x18:
                // RR B
                instruction = RR(op: self.B)
                instructionLength = 2
            case 0x19:
                // RR C
                instruction = RR(op: self.C)
                instructionLength = 2
            case 0x1A:
                // RR D
                instruction = RR(op: self.D)
                instructionLength = 2
            case 0x1B:
                // RR E
                instruction = RR(op: self.E)
                instructionLength = 2
            case 0x1C:
                // RR H
                instruction = RR(op: self.H)
                instructionLength = 2
            case 0x1D:
                // RR L
                instruction = RR(op: self.L)
                instructionLength = 2
            case 0x1E:
                // RR (HL)
                instruction = RR(op: self.HL.asPointerOn(self.bus))
                instructionLength = 2
            case 0x1F:
                // RR A
                instruction = RR(op: self.A)
                instructionLength = 2

            case 0x20:
                // SLA B
                instruction = SLA(op: self.B)
                instructionLength = 2
                
            case 0x21:
                // SLA C
                instruction = SLA(op: self.C)
                instructionLength = 2
                
            case 0x22:
                // SLA D
                instruction = SLA(op: self.D)
                instructionLength = 2
                
            case 0x23:
                // SLA E
                instruction = SLA(op: self.E)
                instructionLength = 2
                
            case 0x24:
                // SLA H
                instruction = SLA(op: self.H)
                instructionLength = 2
                
            case 0x25:
                // SLA L
                instruction = SLA(op: self.L)
                instructionLength = 2
                
            case 0x26:
                // SLA (HL)
                instruction = SLA(op: self.HL.asPointerOn(self.bus))
                instructionLength = 2
                
            case 0x27:
                // SLA A
                instruction = SLA(op: self.A)
                instructionLength = 2
                
                
            case 0x38:
                // SRL B
                instruction = SRL(op: self.B)
                instructionLength = 2
                
            case 0x39:
                // SRL C
                instruction = SRL(op: self.C)
                instructionLength = 2
                
            case 0x3A:
                // SRL D
                instruction = SRL(op: self.D)
                instructionLength = 2
                
            case 0x3B:
                // SRL E
                instruction = SRL(op: self.E)
                instructionLength = 2
                
            case 0x3C:
                // SRL H
                instruction = SRL(op: self.H)
                instructionLength = 2
                
            case 0x3D:
                // SRL L
                instruction = SRL(op: self.L)
                instructionLength = 2
                
            case 0x3E:
                // SRL (HL)
                instruction = SRL(op: self.HL.asPointerOn(self.bus))
                instructionLength = 2
                
            case 0x3F:
                // SRL A
                instruction = SRL(op: self.A)
                instructionLength = 2
                
                
            case 0x40:
                // BIT 0, B
                instruction = BIT(op: self.B, bit: 0)
                instructionLength = 2
                
            case 0x41:
                // BIT 0, C
                instruction = BIT(op: self.C, bit: 0)
                instructionLength = 2
                
            case 0x42:
                // BIT 0, D
                instruction = BIT(op: self.D, bit: 0)
                instructionLength = 2
                
            case 0x43:
                // BIT 0, E
                instruction = BIT(op: self.E, bit: 0)
                instructionLength = 2
                
            case 0x44:
                // BIT 0, H
                instruction = BIT(op: self.H, bit: 0)
                instructionLength = 2
                
            case 0x45:
                // BIT 0, L
                instruction = BIT(op: self.L, bit: 0)
                instructionLength = 2
                
            case 0x46:
                // BIT 0, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 0)
                instructionLength = 2
                
            case 0x47:
                // BIT 0, A
                instruction = BIT(op: self.A, bit: 0)
                instructionLength = 2
                
                
            case 0x48:
                // BIT 1, B
                instruction = BIT(op: self.B, bit: 1)
                instructionLength = 2
                
            case 0x49:
                // BIT 1, C
                instruction = BIT(op: self.C, bit: 1)
                instructionLength = 2
                
            case 0x4A:
                // BIT 1, D
                instruction = BIT(op: self.D, bit: 1)
                instructionLength = 2
                
            case 0x4B:
                // BIT 1, E
                instruction = BIT(op: self.E, bit: 1)
                instructionLength = 2
                
            case 0x4C:
                // BIT 1, H
                instruction = BIT(op: self.H, bit: 1)
                instructionLength = 2
                
            case 0x4D:
                // BIT 1, L
                instruction = BIT(op: self.L, bit: 1)
                instructionLength = 2
                
            case 0x4E:
                // BIT 1, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 1)
                instructionLength = 2
                
            case 0x4F:
                // BIT 1, A
                instruction = BIT(op: self.A, bit: 1)
                instructionLength = 2
                
                
            case 0x50:
                // BIT 2, B
                instruction = BIT(op: self.B, bit: 2)
                instructionLength = 2
                
            case 0x51:
                // BIT 2, C
                instruction = BIT(op: self.C, bit: 2)
                instructionLength = 2
                
            case 0x52:
                // BIT 2, D
                instruction = BIT(op: self.D, bit: 2)
                instructionLength = 2
                
            case 0x53:
                // BIT 2, E
                instruction = BIT(op: self.E, bit: 2)
                instructionLength = 2
                
            case 0x54:
                // BIT 2, H
                instruction = BIT(op: self.H, bit: 2)
                instructionLength = 2
                
            case 0x55:
                // BIT 2, L
                instruction = BIT(op: self.L, bit: 2)
                instructionLength = 2
                
            case 0x56:
                // BIT 2, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 2)
                instructionLength = 2
                
            case 0x57:
                // BIT 2, A
                instruction = BIT(op: self.A, bit: 2)
                instructionLength = 2
                
                
            case 0x58:
                // BIT 3, B
                instruction = BIT(op: self.B, bit: 3)
                instructionLength = 2
                
            case 0x59:
                // BIT 3, C
                instruction = BIT(op: self.C, bit: 3)
                instructionLength = 2
                
            case 0x5A:
                // BIT 3, D
                instruction = BIT(op: self.D, bit: 3)
                instructionLength = 2
                
            case 0x5B:
                // BIT 3, E
                instruction = BIT(op: self.E, bit: 3)
                instructionLength = 2
                
            case 0x5C:
                // BIT 3, H
                instruction = BIT(op: self.H, bit: 3)
                instructionLength = 2
                
            case 0x5D:
                // BIT 3, L
                instruction = BIT(op: self.L, bit: 3)
                instructionLength = 2
                
            case 0x5E:
                // BIT 3, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 3)
                instructionLength = 2
                
            case 0x5F:
                // BIT 3, A
                instruction = BIT(op: self.A, bit: 3)
                instructionLength = 2
                
                
                
            case 0x60:
                // BIT 4, B
                instruction = BIT(op: self.B, bit: 4)
                instructionLength = 2
                
            case 0x61:
                // BIT 4, C
                instruction = BIT(op: self.C, bit: 4)
                instructionLength = 2
                
            case 0x62:
                // BIT 4, D
                instruction = BIT(op: self.D, bit: 4)
                instructionLength = 2
                
            case 0x63:
                // BIT 4, E
                instruction = BIT(op: self.E, bit: 4)
                instructionLength = 2
                
            case 0x64:
                // BIT 4, H
                instruction = BIT(op: self.H, bit: 4)
                instructionLength = 2
                
            case 0x65:
                // BIT 4, L
                instruction = BIT(op: self.L, bit: 4)
                instructionLength = 2
                
            case 0x66:
                // BIT 4, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 4)
                instructionLength = 2
                
            case 0x67:
                // BIT 4, A
                instruction = BIT(op: self.A, bit: 4)
                instructionLength = 2
                
                
                
            case 0x68:
                // BIT 5, B
                instruction = BIT(op: self.B, bit: 5)
                instructionLength = 2
                
            case 0x69:
                // BIT 5, C
                instruction = BIT(op: self.C, bit: 5)
                instructionLength = 2
                
            case 0x6A:
                // BIT 5, D
                instruction = BIT(op: self.D, bit: 5)
                instructionLength = 2
                
            case 0x6B:
                // BIT 5, E
                instruction = BIT(op: self.E, bit: 5)
                instructionLength = 2
                
            case 0x6C:
                // BIT 5, H
                instruction = BIT(op: self.H, bit: 5)
                instructionLength = 2
                
            case 0x6D:
                // BIT 5, L
                instruction = BIT(op: self.L, bit: 5)
                instructionLength = 2
                
            case 0x6E:
                // BIT 5, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 5)
                instructionLength = 2
                
            case 0x6F:
                // BIT 5, A
                instruction = BIT(op: self.A, bit: 5)
                instructionLength = 2
                
                
                
            case 0x70:
                // BIT 6, B
                instruction = BIT(op: self.B, bit: 6)
                instructionLength = 2
                
            case 0x71:
                // BIT 6, C
                instruction = BIT(op: self.C, bit: 6)
                instructionLength = 2
                
            case 0x72:
                // BIT 6, D
                instruction = BIT(op: self.D, bit: 6)
                instructionLength = 2
                
            case 0x73:
                // BIT 6, E
                instruction = BIT(op: self.E, bit: 6)
                instructionLength = 2
                
            case 0x74:
                // BIT 6, H
                instruction = BIT(op: self.H, bit: 6)
                instructionLength = 2
                
            case 0x75:
                // BIT 6, L
                instruction = BIT(op: self.L, bit: 6)
                instructionLength = 2
                
            case 0x76:
                // BIT 6, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 6)
                instructionLength = 2
                
            case 0x77:
                // BIT 6, A
                instruction = BIT(op: self.A, bit: 6)
                instructionLength = 2
                
                
                
            case 0x78:
                // BIT 7, B
                instruction = BIT(op: self.B, bit: 7)
                instructionLength = 2
                
            case 0x79:
                // BIT 7, C
                instruction = BIT(op: self.C, bit: 7)
                instructionLength = 2
                
            case 0x7A:
                // BIT 7, D
                instruction = BIT(op: self.D, bit: 7)
                instructionLength = 2
                
            case 0x7B:
                // BIT 7, E
                instruction = BIT(op: self.E, bit: 7)
                instructionLength = 2
                
            case 0x7C:
                // BIT 7, H
                instruction = BIT(op: self.H, bit: 7)
                instructionLength = 2
                
            case 0x7D:
                // BIT 7, L
                instruction = BIT(op: self.L, bit: 7)
                instructionLength = 2
                
            case 0x7E:
                // BIT 7, (HL)
                instruction = BIT(op: self.HL.asPointerOn(self.bus), bit: 7)
                instructionLength = 2
                
            case 0x7F:
                // BIT 7, A
                instruction = BIT(op: self.A, bit: 7)
                instructionLength = 2
                
                
            case 0x80:
                // RES 0, B
                instruction = RES(op: self.B, bit: 0)
                instructionLength = 2
                
            case 0x81:
                // RES 0, C
                instruction = RES(op: self.C, bit: 0)
                instructionLength = 2
                
            case 0x82:
                // RES 0, D
                instruction = RES(op: self.D, bit: 0)
                instructionLength = 2
                
            case 0x83:
                // RES 0, E
                instruction = RES(op: self.E, bit: 0)
                instructionLength = 2
                
            case 0x84:
                // RES 0, H
                instruction = RES(op: self.H, bit: 0)
                instructionLength = 2
                
            case 0x85:
                // RES 0, L
                instruction = RES(op: self.L, bit: 0)
                instructionLength = 2
                
            case 0x86:
                // RES 0, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 0)
                instructionLength = 2
                
            case 0x87:
                // RES 0, A
                instruction = RES(op: self.A, bit: 0)
                instructionLength = 2
                
                
            case 0x88:
                // RES 1, B
                instruction = RES(op: self.B, bit: 1)
                instructionLength = 2
                
            case 0x89:
                // RES 1, C
                instruction = RES(op: self.C, bit: 1)
                instructionLength = 2
                
            case 0x8A:
                // RES 1, D
                instruction = RES(op: self.D, bit: 1)
                instructionLength = 2
                
            case 0x8B:
                // RES 1, E
                instruction = RES(op: self.E, bit: 1)
                instructionLength = 2
                
            case 0x8C:
                // RES 1, H
                instruction = RES(op: self.H, bit: 1)
                instructionLength = 2
                
            case 0x8D:
                // RES 1, L
                instruction = RES(op: self.L, bit: 1)
                instructionLength = 2
                
            case 0x8E:
                // RES 1, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 1)
                instructionLength = 2
                
            case 0x8F:
                // RES 1, A
                instruction = RES(op: self.A, bit: 1)
                instructionLength = 2
                
                
            case 0x90:
                // RES 2, B
                instruction = RES(op: self.B, bit: 2)
                instructionLength = 2
                
            case 0x91:
                // RES 2, C
                instruction = RES(op: self.C, bit: 2)
                instructionLength = 2
                
            case 0x92:
                // RES 2, D
                instruction = RES(op: self.D, bit: 2)
                instructionLength = 2
                
            case 0x93:
                // RES 2, E
                instruction = RES(op: self.E, bit: 2)
                instructionLength = 2
                
            case 0x94:
                // RES 2, H
                instruction = RES(op: self.H, bit: 2)
                instructionLength = 2
                
            case 0x95:
                // RES 2, L
                instruction = RES(op: self.L, bit: 2)
                instructionLength = 2
                
            case 0x96:
                // RES 2, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 2)
                instructionLength = 2
                
            case 0x97:
                // RES 2, A
                instruction = RES(op: self.A, bit: 2)
                instructionLength = 2
                
                
            case 0x98:
                // RES 3, B
                instruction = RES(op: self.B, bit: 3)
                instructionLength = 2
                
            case 0x99:
                // RES 3, C
                instruction = RES(op: self.C, bit: 3)
                instructionLength = 2
                
            case 0x9A:
                // RES 3, D
                instruction = RES(op: self.D, bit: 3)
                instructionLength = 2
                
            case 0x9B:
                // RES 3, E
                instruction = RES(op: self.E, bit: 3)
                instructionLength = 2
                
            case 0x9C:
                // RES 3, H
                instruction = RES(op: self.H, bit: 3)
                instructionLength = 2
                
            case 0x9D:
                // RES 3, L
                instruction = RES(op: self.L, bit: 3)
                instructionLength = 2
                
            case 0x9E:
                // RES 3, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 3)
                instructionLength = 2
                
            case 0x9F:
                // RES 3, A
                instruction = RES(op: self.A, bit: 3)
                instructionLength = 2
                
                
                
            case 0xA0:
                // RES 4, B
                instruction = RES(op: self.B, bit: 4)
                instructionLength = 2
                
            case 0xA1:
                // RES 4, C
                instruction = RES(op: self.C, bit: 4)
                instructionLength = 2
                
            case 0xA2:
                // RES 4, D
                instruction = RES(op: self.D, bit: 4)
                instructionLength = 2
                
            case 0xA3:
                // RES 4, E
                instruction = RES(op: self.E, bit: 4)
                instructionLength = 2
                
            case 0xA4:
                // RES 4, H
                instruction = RES(op: self.H, bit: 4)
                instructionLength = 2
                
            case 0xA5:
                // RES 4, L
                instruction = RES(op: self.L, bit: 4)
                instructionLength = 2
                
            case 0xA6:
                // RES 4, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 4)
                instructionLength = 2
                
            case 0xA7:
                // RES 4, A
                instruction = RES(op: self.A, bit: 4)
                instructionLength = 2
                
                
                
            case 0xA8:
                // RES 5, B
                instruction = RES(op: self.B, bit: 5)
                instructionLength = 2
                
            case 0xA9:
                // RES 5, C
                instruction = RES(op: self.C, bit: 5)
                instructionLength = 2
                
            case 0xAA:
                // RES 5, D
                instruction = RES(op: self.D, bit: 5)
                instructionLength = 2
                
            case 0xAB:
                // RES 5, E
                instruction = RES(op: self.E, bit: 5)
                instructionLength = 2
                
            case 0xAC:
                // RES 5, H
                instruction = RES(op: self.H, bit: 5)
                instructionLength = 2
                
            case 0xAD:
                // RES 5, L
                instruction = RES(op: self.L, bit: 5)
                instructionLength = 2
                
            case 0xAE:
                // RES 5, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 5)
                instructionLength = 2
                
            case 0xAF:
                // RES 5, A
                instruction = RES(op: self.A, bit: 5)
                instructionLength = 2
                
                
                
            case 0xB0:
                // RES 6, B
                instruction = RES(op: self.B, bit: 6)
                instructionLength = 2
                
            case 0xB1:
                // RES 6, C
                instruction = RES(op: self.C, bit: 6)
                instructionLength = 2
                
            case 0xB2:
                // RES 6, D
                instruction = RES(op: self.D, bit: 6)
                instructionLength = 2
                
            case 0xB3:
                // RES 6, E
                instruction = RES(op: self.E, bit: 6)
                instructionLength = 2
                
            case 0xB4:
                // RES 6, H
                instruction = RES(op: self.H, bit: 6)
                instructionLength = 2
                
            case 0xB5:
                // RES 6, L
                instruction = RES(op: self.L, bit: 6)
                instructionLength = 2
                
            case 0xB6:
                // RES 6, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 6)
                instructionLength = 2
                
            case 0xB7:
                // RES 6, A
                instruction = RES(op: self.A, bit: 6)
                instructionLength = 2
                
                
                
            case 0xB8:
                // RES 7, B
                instruction = RES(op: self.B, bit: 7)
                instructionLength = 2
                
            case 0xB9:
                // RES 7, C
                instruction = RES(op: self.C, bit: 7)
                instructionLength = 2
                
            case 0xBA:
                // RES 7, D
                instruction = RES(op: self.D, bit: 7)
                instructionLength = 2
                
            case 0xBB:
                // RES 7, E
                instruction = RES(op: self.E, bit: 7)
                instructionLength = 2
                
            case 0xBC:
                // RES 7, H
                instruction = RES(op: self.H, bit: 7)
                instructionLength = 2
                
            case 0xBD:
                // RES 7, L
                instruction = RES(op: self.L, bit: 7)
                instructionLength = 2
                
            case 0xBE:
                // RES 7, (HL)
                instruction = RES(op: self.HL.asPointerOn(self.bus), bit: 7)
                instructionLength = 2
                
            case 0xBF:
                // RES 7, A
                instruction = RES(op: self.A, bit: 7)
                instructionLength = 2
                
                
                
            case 0xC0:
                // SET 0, B
                instruction = SET(op: self.B, bit: 0)
                instructionLength = 2
                
            case 0xC1:
                // SET 0, C
                instruction = SET(op: self.C, bit: 0)
                instructionLength = 2
                
            case 0xC2:
                // SET 0, D
                instruction = SET(op: self.D, bit: 0)
                instructionLength = 2
                
            case 0xC3:
                // SET 0, E
                instruction = SET(op: self.E, bit: 0)
                instructionLength = 2
                
            case 0xC4:
                // SET 0, H
                instruction = SET(op: self.H, bit: 0)
                instructionLength = 2
                
            case 0xC5:
                // SET 0, L
                instruction = SET(op: self.L, bit: 0)
                instructionLength = 2
                
            case 0xC6:
                // SET 0, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 0)
                instructionLength = 2
                
            case 0xC7:
                // SET 0, A
                instruction = SET(op: self.A, bit: 0)
                instructionLength = 2
                
                
            case 0xC8:
                // SET 1, B
                instruction = SET(op: self.B, bit: 1)
                instructionLength = 2
                
            case 0xC9:
                // SET 1, C
                instruction = SET(op: self.C, bit: 1)
                instructionLength = 2
                
            case 0xCA:
                // SET 1, D
                instruction = SET(op: self.D, bit: 1)
                instructionLength = 2
                
            case 0xCB:
                // SET 1, E
                instruction = SET(op: self.E, bit: 1)
                instructionLength = 2
                
            case 0xCC:
                // SET 1, H
                instruction = SET(op: self.H, bit: 1)
                instructionLength = 2
                
            case 0xCD:
                // SET 1, L
                instruction = SET(op: self.L, bit: 1)
                instructionLength = 2
                
            case 0xCE:
                // SET 1, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 1)
                instructionLength = 2
                
            case 0xCF:
                // SET 1, A
                instruction = SET(op: self.A, bit: 1)
                instructionLength = 2

                
                
            case 0xD0:
                // SET 2, B
                instruction = SET(op: self.B, bit: 2)
                instructionLength = 2
                
            case 0xD1:
                // SET 2, C
                instruction = SET(op: self.C, bit: 2)
                instructionLength = 2
                
            case 0xD2:
                // SET 2, D
                instruction = SET(op: self.D, bit: 2)
                instructionLength = 2
                
            case 0xD3:
                // SET 2, E
                instruction = SET(op: self.E, bit: 2)
                instructionLength = 2
                
            case 0xD4:
                // SET 2, H
                instruction = SET(op: self.H, bit: 2)
                instructionLength = 2
                
            case 0xD5:
                // SET 2, L
                instruction = SET(op: self.L, bit: 2)
                instructionLength = 2
                
            case 0xD6:
                // SET 2, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 2)
                instructionLength = 2
                
            case 0xD7:
                // SET 2, A
                instruction = SET(op: self.A, bit: 2)
                instructionLength = 2
                
                
            case 0xD8:
                // SET 3, B
                instruction = SET(op: self.B, bit: 3)
                instructionLength = 2
                
            case 0xD9:
                // SET 3, C
                instruction = SET(op: self.C, bit: 3)
                instructionLength = 2
                
            case 0xDA:
                // SET 3, D
                instruction = SET(op: self.D, bit: 3)
                instructionLength = 2
                
            case 0xDB:
                // SET 3, E
                instruction = SET(op: self.E, bit: 3)
                instructionLength = 2
                
            case 0xDC:
                // SET 3, H
                instruction = SET(op: self.H, bit: 3)
                instructionLength = 2
                
            case 0xDD:
                // SET 3, L
                instruction = SET(op: self.L, bit: 3)
                instructionLength = 2
                
            case 0xDE:
                // SET 3, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 3)
                instructionLength = 2
                
            case 0xDF:
                // SET 3, A
                instruction = SET(op: self.A, bit: 3)
                instructionLength = 2
                
                
                
            case 0xE0:
                // SET 4, B
                instruction = SET(op: self.B, bit: 4)
                instructionLength = 2
                
            case 0xE1:
                // SET 4, C
                instruction = SET(op: self.C, bit: 4)
                instructionLength = 2
                
            case 0xE2:
                // SET 4, D
                instruction = SET(op: self.D, bit: 4)
                instructionLength = 2
                
            case 0xE3:
                // SET 4, E
                instruction = SET(op: self.E, bit: 4)
                instructionLength = 2
                
            case 0xE4:
                // SET 4, H
                instruction = SET(op: self.H, bit: 4)
                instructionLength = 2
                
            case 0xE5:
                // SET 4, L
                instruction = SET(op: self.L, bit: 4)
                instructionLength = 2
                
            case 0xE6:
                // SET 4, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 4)
                instructionLength = 2
                
            case 0xE7:
                // SET 4, A
                instruction = SET(op: self.A, bit: 4)
                instructionLength = 2
                
                
                
            case 0xE8:
                // SET 5, B
                instruction = SET(op: self.B, bit: 5)
                instructionLength = 2
                
            case 0xE9:
                // SET 5, C
                instruction = SET(op: self.C, bit: 5)
                instructionLength = 2
                
            case 0xEA:
                // SET 5, D
                instruction = SET(op: self.D, bit: 5)
                instructionLength = 2
                
            case 0xEB:
                // SET 5, E
                instruction = SET(op: self.E, bit: 5)
                instructionLength = 2
                
            case 0xEC:
                // SET 5, H
                instruction = SET(op: self.H, bit: 5)
                instructionLength = 2
                
            case 0xED:
                // SET 5, L
                instruction = SET(op: self.L, bit: 5)
                instructionLength = 2
                
            case 0xEE:
                // SET 5, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 5)
                instructionLength = 2
                
            case 0xEF:
                // SET 5, A
                instruction = SET(op: self.A, bit: 5)
                instructionLength = 2
                
                
                
            case 0xF0:
                // SET 6, B
                instruction = SET(op: self.B, bit: 6)
                instructionLength = 2
                
            case 0xF1:
                // SET 6, C
                instruction = SET(op: self.C, bit: 6)
                instructionLength = 2
                
            case 0xF2:
                // SET 6, D
                instruction = SET(op: self.D, bit: 6)
                instructionLength = 2
                
            case 0xF3:
                // SET 6, E
                instruction = SET(op: self.E, bit: 6)
                instructionLength = 2
                
            case 0xF4:
                // SET 6, H
                instruction = SET(op: self.H, bit: 6)
                instructionLength = 2
                
            case 0xF5:
                // SET 6, L
                instruction = SET(op: self.L, bit: 6)
                instructionLength = 2
                
            case 0xF6:
                // SET 6, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 6)
                instructionLength = 2
                
            case 0xF7:
                // SET 6, A
                instruction = SET(op: self.A, bit: 6)
                instructionLength = 2
                
                
                
            case 0xF8:
                // SET 7, B
                instruction = SET(op: self.B, bit: 7)
                instructionLength = 2
                
            case 0xF9:
                // SET 7, C
                instruction = SET(op: self.C, bit: 7)
                instructionLength = 2
                
            case 0xFA:
                // SET 7, D
                instruction = SET(op: self.D, bit: 7)
                instructionLength = 2
                
            case 0xFB:
                // SET 7, E
                instruction = SET(op: self.E, bit: 7)
                instructionLength = 2
                
            case 0xFC:
                // SET 7, H
                instruction = SET(op: self.H, bit: 7)
                instructionLength = 2
                
            case 0xFD:
                // SET 7, L
                instruction = SET(op: self.L, bit: 7)
                instructionLength = 2
                
            case 0xFE:
                // SET 7, (HL)
                instruction = SET(op: self.HL.asPointerOn(self.bus), bit: 7)
                instructionLength = 2
                
            case 0xFF:
                // SET 7, A
                instruction = SET(op: self.A, bit: 7)
                instructionLength = 2
                
            default:
                break
            }
            
        default:
            break
        }
        
        
        if let instruction = instruction {
//            print("C \(PC.read().hexString): ", terminator: "")
//            for i in 0..<instructionLength {
//                print("\(bus.read(PC.read()+i).hexString) ", terminator: "")
//            }
//            print("\n\t\(instruction)\n")
            
            //@todo make PC-incrementing common
            self.PC.write(self.PC.read() + instructionLength)
        }
        
        return instruction
    }
}
