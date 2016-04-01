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
    /// Parity/overflow flag
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
            
        case 0x0D:
            // DEC C
            instruction = DEC(operand: self.C)
            instructionLength = 1
            
        case 0x0F:
            // RRCA
            instruction = RRCA()
            instructionLength = 1
            
        case 0x10:
            // DJNZ
            let displacement = Int8(bitPattern: memory.read8(PC.read()+1))
            instruction = DJNZ(displacement: displacement)
            instructionLength = 2
            
        case 0x12:
            // LD (DE), A
            instruction = LD(dest: Register16Indirect8(register: self.DE, memory: self.memory), src: self.A)
            instructionLength = 1
            
        case 0x18:
            // JR n
            let displacement = Int8(memory.read8(PC.read()+1))
            instruction = JP(condition: nil, dest: ImmediateDisplaced16(base: PC.read()+2, displacement: displacement))
            instructionLength = 2
            
        case 0x21:
            // LD HL, nn
            let val = memory.read16(PC.read()+1)
            instruction = LD(dest: self.HL, src: Immediate16(val: val))
            instructionLength = 3
            
        case 0x3E:
            // LD A, n
            let val = memory.read8(PC.read()+1)
            instruction = LD(dest: self.A, src: Immediate8(val: val))
            instructionLength = 1
            
        case 0x3F:
            // CCF
            instruction = CCF()
            instructionLength = 1
            
        case 0x66:
            // LD H, (HL)
            instruction = LD(dest: self.H, src: Register16Indirect8(register: self.HL, memory: self.memory))
            instructionLength = 1
            
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
            instructionLength += 2
            
        default:
            print(String(format: "Unrecognized opcode 0x%02X at PC 0x%04X", firstByte, PC.read()))
        }
        
        //@warn we should probably only alter the PC if the instruction doesn't do so itself
        PC.write(PC.read() + instructionLength)
        return instruction
    }
}