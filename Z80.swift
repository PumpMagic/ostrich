//
//  Z80.swift
//  ostrich
//
//  Created by Ryan Conway on 1/6/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/**
 Represents a Zilog Z80 CPU.
 */
public class Z80 {
    // main registers
    /// A, AKA the Accumulator
    let A: Register8
    let B: Register8
    let C: Register8
    let D: Register8
    let E: Register8
    /// F, aka the Flags
    let F: Register8
    let H: Register8
    let L: Register8
    
    // alternate registers
    let Ap: Register8
    let Bp: Register8
    let Cp: Register8
    let Dp: Register8
    let Ep: Register8
    let Fp: Register8
    let Hp: Register8
    let Lp: Register8
    
    // index registers
    let IX: Register16
    let IY: Register16
    let SP: Register16
    
    // other registers
    let I: Register8 // interrupt vector
    let R: Register8 // refresh
    
    // program counter
    let PC: Register16
    
    // flags - computed from F
    /// Sign flag
    let SF: Flag
    /// Zero flag
    let ZF: Flag
    /// Half-carry flag
    let HF: Flag
    /// Parity/overflow flag. Parity 0: odd number of high bits. Parity 1: even number of high bits.
    let PVF: Flag
    /// Add/subtract flag
    let NF: Flag
    /// Carry flag
    let CF: Flag
    
    // computed main registers
    let AF: Register16Computed
    let BC: Register16Computed
    let DE: Register16Computed
    let HL: Register16Computed
    
    // computed alternate registers
    let AFp: Register16Computed
    let BCp: Register16Computed
    let DEp: Register16Computed
    let HLp: Register16Computed
    
    
    // ROM this CPU is wired to - this is a connection, not something owned
    let memory: Memory

    public init(memory: Memory) {
        self.A = Register8(val: 0)
        self.B = Register8(val: 0)
        self.C = Register8(val: 0)
        self.D = Register8(val: 0)
        self.E = Register8(val: 0)
        self.F = Register8(val: 0)
        self.H = Register8(val: 0)
        self.L = Register8(val: 0)
        
        self.Ap = Register8(val: 0)
        self.Bp = Register8(val: 0)
        self.Cp = Register8(val: 0)
        self.Dp = Register8(val: 0)
        self.Ep = Register8(val: 0)
        self.Fp = Register8(val: 0)
        self.Hp = Register8(val: 0)
        self.Lp = Register8(val: 0)
        
        self.IX = Register16(val: 0)
        self.IY = Register16(val: 0)
        self.SP = Register16(val: 0)
        
        self.I = Register8(val: 0)
        self.R = Register8(val: 0)
        
        self.PC = Register16(val: 0x100) //@todo don't init this here?
        
        self.SF = Flag(reg: F, bitNumber: 7)
        self.ZF = Flag(reg: F, bitNumber: 6)
        self.HF = Flag(reg: F, bitNumber: 4)
        self.PVF = Flag(reg: F, bitNumber: 2)
        self.NF = Flag(reg: F, bitNumber: 1)
        self.CF = Flag(reg: F, bitNumber: 0)
        
        self.AF = Register16Computed(high: self.A, low: self.F)
        self.BC = Register16Computed(high: self.B, low: self.C)
        self.DE = Register16Computed(high: self.D, low: self.E)
        self.HL = Register16Computed(high: self.H, low: self.L)
        
        self.AFp = Register16Computed(high: self.Ap, low: self.Fp)
        self.BCp = Register16Computed(high: self.Bp, low: self.Cp)
        self.DEp = Register16Computed(high: self.Dp, low: self.Ep)
        self.HLp = Register16Computed(high: self.Hp, low: self.Lp)
        
        self.memory = memory
    }
    
    public func setSP(sp: Address) {
        self.SP.write(sp)
    }
    
    public func setPC(pc: Address) {
        self.PC.write(pc)
    }
    
    public func setA(a: UInt8) {
        self.A.write(a)
    }
    
    public func getInstruction() -> Instruction? {
        let firstByte = memory.read8(PC.read())
        
        var instruction: Instruction? = nil
        var instructionLength: UInt16 = 1
        
        switch firstByte {
        case 0x00:
            // NOP
            instruction = NOP()
            instructionLength = 1
            
        // Manual: "The first n operand after the op code is the low-order byte."
        //      -> First byte -> C
        //      -> Second byte -> B
        // So as long as Memory.read16 returns the endianness LD.src expects, we're fine, right?
        case 0x01:
            // LD BC, nn
            let val = memory.read16(PC.read()+1)
            instruction = LD(dest: self.BC, src: Immediate16(val: val))
            instructionLength = 3
            
        case 0x02:
            // LD (BC), A
            instruction = LD(dest: self.BC.asIndirectInto(self.memory), src: self.A)
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
            let val = memory.read8(PC.read()+1)
            instruction = LD(dest: self.B, src: Immediate8(val: val))
            instructionLength = 1
            
        case 0x07:
            // RLCA
            instruction = RLCA()
            instructionLength = 1
            
        case 0x08:
            // EX AF, AF'
            instruction = EX(op1: self.AF, op2: self.AFp)
            instructionLength = 1
            
        case 0x09:
            // ADD HL, BC
            instruction = ADD16(op1: self.HL, op2: self.BC)
            instructionLength = 1
            
        case 0x0A:
            // LD A, (BC)
            instruction = LD(dest: self.A, src: self.BC.asIndirectInto(memory))
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
            
        case 0x0F:
            // RRCA
            instruction = RRCA()
            instructionLength = 1
            
        case 0x09:
            // ADD HL, BC
            instruction = ADD16(op1: self.HL, op2: self.BC)
            instructionLength = 1
            
        case 0x10:
            // DJNZ
            let displacement = Int8(bitPattern: memory.read8(PC.read()+1))
            instruction = DJNZ(displacement: displacement)
            instructionLength = 2
            
        case 0x12:
            // LD (DE), A
            instruction = LD(dest: self.DE.asIndirectInto(self.memory), src: self.A)
            instructionLength = 1
            
        case 0x18:
            // JR n
            let displacement = Int8(memory.read8(PC.read()+1))
            instruction = JP(condition: nil, dest: ImmediateDisplaced16(base: PC.read()+2, displacement: displacement))
            instructionLength = 2
            
        case 0x19:
            // ADD HL, DE
            instruction = ADD16(op1: self.HL, op2: self.DE)
            instructionLength = 1
            
        case 0x21:
            // LD HL, nn
            let val = memory.read16(PC.read()+1)
            instruction = LD(dest: self.HL, src: Immediate16(val: val))
            instructionLength = 3
            
        case 0x29:
            // ADD HL, HL
            instruction = ADD16(op1: self.HL, op2: self.HL)
            instructionLength = 1
            
        case 0x39:
            // ADD HL, SP
            instruction = ADD16(op1: self.HL, op2: self.SP)
            instructionLength = 1
            
        case 0x3E:
            // LD A, n
            let val = memory.read8(PC.read()+1)
            instruction = LD(dest: self.A, src: Immediate8(val: val))
            instructionLength = 1
            
        case 0x3F:
            // CCF
            instruction = CCF()
            instructionLength = 1
            
        case 0x40:
            // LD B, B
            instruction = LD(dest: self.B, src: self.B)
            instructionLength = 1
            
        case 0x50:
            // LD D, B
            instruction = LD(dest: self.D, src: self.B)
            instructionLength = 1
            
        case 0x60:
            // LD H, B
            instruction = LD(dest: self.H, src: self.B)
            instructionLength = 1
            
        case 0x66:
            // LD H, (HL)
            instruction = LD(dest: self.H, src: self.HL.asIndirectInto(self.memory))
            instructionLength = 1
            
        case 0x70:
            // LD (HL), B
            instruction = LD(dest: self.HL.asIndirectInto(self.memory), src: self.B)
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
            instruction = ADD8(op1: self.A, op2: self.HL.asIndirectInto(self.memory))
            instructionLength = 1
        case 0x87:
            // ADD A, A
            instruction = ADD8(op1: self.A, op2: self.A)
            instructionLength = 1
            
        case 0xC6:
            // ADD A, n
            let val = memory.read8(PC.read()+1)
            instruction = ADD8(op1: self.A, op2: Immediate8(val: val))
            instructionLength = 2
            
        case 0xC3:
            // JP nn
            let addr = memory.read16(PC.read()+1)
            instruction = JP(condition: nil, dest: Immediate16(val: addr))
            instructionLength = 3
            
        /*
         case 0xCE:
         let num = memory.read8(PC.read()+1)
         instruction = ADC(operand: Immediate8(val: num))
         instructionLength = 2
         */
            
        case 0xDF:
            // RST 0x18
            instruction = RST(restartAddress: 0x18)
            instructionLength = 1
            
        case 0xE0:
            // RET PO
            instruction = RET(condition: Condition(flag: self.PVF, target: false))
            instructionLength = 1
            break
            
        case 0xF3:
            let num = memory.read8(PC.read()+1)
            instruction = CP(op: Immediate8(val: num))
            instructionLength = 2
            
            
        case 0xDD:
            // IX instructions
            let secondByte = memory.read8(PC.read()+1)
            switch secondByte {
            case 0x09:
                // ADD IX, BC
                instruction = ADD16(op1: self.IX, op2: self.BC)
                instructionLength = 2
            case 0x19:
                // ADD IX, DE
                instruction = ADD16(op1: self.IX, op2: self.DE)
                instructionLength = 2
            case 0x29:
                // ADD IX, IX
                instruction = ADD16(op1: self.IX, op2: self.IX)
                instructionLength = 2
            case 0x39:
                // ADD IX, SP
                instruction = ADD16(op1: self.IX, op2: self.SP)
                instructionLength = 2
                
            default:
                let combinedOpcode: UInt16 = make16(high: firstByte, low: secondByte)
                print(String(format: "Unrecognized opcode 0x%04X at PC 0x%04X", combinedOpcode, PC.read()))
            }
            
        case 0xFD:
            // IY instructions
            //@todo it wouldn't be very hard to make some higher-level code that handles both
            //IX instructions and IY instructions
            let secondByte = memory.read8(PC.read()+1)
            switch secondByte {
            case 0x09:
                // ADD IY, BC
                instruction = ADD16(op1: self.IY, op2: self.BC)
                instructionLength = 2
            case 0x19:
                // ADD IY, DE
                instruction = ADD16(op1: self.IY, op2: self.DE)
                instructionLength = 2
            case 0x29:
                // ADD IY, IX
                instruction = ADD16(op1: self.IY, op2: self.IX)
                instructionLength = 2
            case 0x39:
                // ADD IY, SP
                instruction = ADD16(op1: self.IY, op2: self.SP)
                instructionLength = 2
                
            default:
                let combinedOpcode: UInt16 = make16(high: firstByte, low: secondByte)
                print(String(format: "Unrecognized opcode 0x%04X at PC 0x%04X", combinedOpcode, PC.read()))
            }
            
            
        default:
            print(String(format: "Unrecognized opcode 0x%02X at PC 0x%04X", firstByte, PC.read()))
        }
        
        //@warn we should probably only alter the PC if the instruction doesn't do so itself
        PC.write(PC.read() + instructionLength)
        return instruction
    }
}