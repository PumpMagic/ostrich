//
//  Z80.swift
//  ostrich
//
//  Created by Ryan Conway on 1/6/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Representation a Zilog Z80 CPU.
public class Z80: Intel8080Like {
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
    
    // other registers
    /// interrupt page address
    let I: Register8
    /// memory refresh
    let R: Register8
    
    /// program counter
    let PC: Register16
    
    /// stack pointer
    let SP: Register16
    
    // index registers
    let IX: Register16
    let IY: Register16
    
    // flags - computed from F
    /// Sign flag. True: positive. False: negative.
    let SF: Flag
    /// Zero flag
    let ZF: Flag
    /// Half-carry flag
    let HF: Flag
    /// Parity/overflow flag. False: odd number of high bits. True: even number of high bits.
    let PVF: Flag
    /// Add/subtract flag
    let NF: Flag
    /// Carry flag
    let CF: Flag
    
    // logical 16-bit main registers
    let AF: Register16Computed
    let BC: Register16Computed
    let DE: Register16Computed
    let HL: Register16Computed
    
    // logical 16-bit alternate registers
    let AFp: Register16Computed
    let BCp: Register16Computed
    let DEp: Register16Computed
    let HLp: Register16Computed
    
    
    /// interrupt
    var IFF1: FlipFlop
    var IFF2: FlipFlop
    
    var instructionContext: Intel8080InstructionContext
    
    
    let bus: DataBus
    
    
    //@todo emulate all necessary pins (see user manual pg. 17)
    // at least add an interrupt() and maybe nmi()

    public init(bus: DataBus) {
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
        
        self.PC = Register16(val: 0x100) //@todo don't init this here
        
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
        
        
        self.IFF1 = .Disabled
        self.IFF2 = .Disabled
        
        self.instructionContext = Intel8080InstructionContext(lastInstructionWasDI: false, lastInstructionWasEI: false)
        
        self.bus = bus
    }
    
    // Utility methods
    public func setSP(sp: Address) {
        self.SP.write(sp)
    }
    
    public func setPC(pc: Address) {
        self.PC.write(pc)
    }
    
    public func setA(a: UInt8) {
        self.A.write(a)
    }
    
    public func injectCall(addr: Address) {
        let instruction = CALL(condition: nil, dest: Immediate16(val: addr))
        instruction.runOn(self)
    }
    
    /// Stack pointer and program counter debug string
    var pcsp: String { return "\tSP: \(self.SP.read().hexString)\n\tPC: \(self.PC.read().hexString)" }

    
    public func runUntil(instructionType: String) {
        //@todo this is a hacky convenience function, how can we better detect a given instruction without inspecting type?
        var iteration = 1
        repeat {
            let lastInstruction = doInstructionCycle()
            iteration += 1
            let inspectedType = String(Mirror(reflecting: lastInstruction).subjectType)
            if inspectedType == instructionType {
                return
            }
        } while true
    }
    
    
    /// Fetches an instruction, runs it, and returns it
    func doInstructionCycle() -> Z80Instruction {
        guard let instruction = self.fetchInstruction() else {
            print("FATAL: unable to fetch instruction")
            exit(1)
        }
        self.executeInstruction(instruction)
        
        return instruction
    }
    
    /// Execute an instruction.
    /// This function has some additional behavior to support things like EI, which has effects delayed by an instruction.
    func executeInstruction(instruction: Z80Instruction) {
        let oldInstructionContext = self.instructionContext
        
        instruction.runOn(self)
        
        if oldInstructionContext.lastInstructionWasDI {
            self.IFF1 = .Disabled
            self.IFF2 = .Disabled
            
            //@warn this behavior may be too lazy
            self.instructionContext.lastInstructionWasDI = false
        }
        if oldInstructionContext.lastInstructionWasEI {
            self.IFF1 = .Enabled
            self.IFF2 = .Enabled
            
            //@warn this behavior may be too lazy
            self.instructionContext.lastInstructionWasEI = false
        }
    }
    
    //@todo make this internal and add a public run() or clock() or something
    func fetchInstruction() -> Z80Instruction? {
        let firstByte = bus.read(PC.read())
        
        var instruction: Z80Instruction? = nil
        var instructionLength: UInt16 = 1
        
        switch firstByte {
        case 0x00:
            // NOP
            instruction = NOP()
            instructionLength = 1
            
        // Manual: "The first n operand after the op code is the low-order byte."
        //      -> First byte -> C
        //      -> Second byte -> B
        // So as long as DataBus.read16 returns the endianness LD.src expects, we're fine, right?
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
            
        case 0x10:
            // DJNZ
            let displacementMinusTwo = Int8(bitPattern: bus.read(PC.read()+1))
            instruction = DJNZ(displacementMinusTwo: displacementMinusTwo)
            instructionLength = 2
            
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
            
        case 0x18:
            // JR n
            let displacement = Int8(bus.read(PC.read()+1))
            instruction = JP(condition: nil, dest: ImmediateDisplaced16(base: PC.read()+2, displacement: displacement))
            instructionLength = 2
            
        case 0x19:
            // ADD HL, DE
            instruction = ADD16(op1: self.HL, op2: self.DE)
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
            instructionLength = 1
            
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
            
        case 0xC0:
            // RET nz
            instruction = RET(condition: Condition(flag: self.ZF, target: false))
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
            
        case 0xD0:
            // RET nc
            instruction = RET(condition: Condition(flag: self.CF, target: false))
            instructionLength = 1
            
        case 0xD2:
            // JP nc, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.CF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xD5:
            // PUSH DE
            instruction = PUSH(operand: self.DE)
            instructionLength = 1
            
        case 0xD8:
            // RET c
            instruction = RET(condition: Condition(flag: self.CF, target: true))
            instructionLength = 1
            
        case 0xDA:
            // JP c, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.CF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xDF:
            // RST 0x18
            instruction = RST(restartAddress: 0x18)
            instructionLength = 1
            
        case 0xE0:
            // RET po
            instruction = RET(condition: Condition(flag: self.PVF, target: false))
            instructionLength = 1
            
        case 0xE2:
            // JP po, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.PVF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xE5:
            // PUSH HL
            instruction = PUSH(operand: self.HL)
            instructionLength = 1
            
        case 0xE8:
            // RET pe
            instruction = RET(condition: Condition(flag: self.PVF, target: true))
            instructionLength = 1
            
        case 0xE9:
            // JP (HL)
            instruction = JP(condition: nil, dest: self.HL)
            instructionLength = 1
            
        case 0xEA:
            // JP pe, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.PVF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xF0:
            // RET p
            instruction = RET(condition: Condition(flag: self.SF, target: true))
            instructionLength = 1
            
        case 0xF2:
            // JP p, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.SF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xF3:
            // DI
            instruction = DI()
            instructionLength = 1
            
        case 0xF5:
            // PUSH AF
            instruction = PUSH(operand: self.AF)
            instructionLength = 1
            
        case 0xF8:
            // RET p
            instruction = RET(condition: Condition(flag: self.SF, target: false))
            instructionLength = 1
            
        case 0xFA:
            // JP m, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.SF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xFB:
            // EI
            instruction = EI()
            instructionLength = 1
            
            
        case 0xDD:
            // IX instructions
            let secondByte = bus.read(PC.read()+1)
            switch secondByte {
            case 0x09:
                // ADD IX, BC
                instruction = ADD16(op1: self.IX, op2: self.BC)
                instructionLength = 2
            case 0x19:
                // ADD IX, DE
                instruction = ADD16(op1: self.IX, op2: self.DE)
                instructionLength = 2
                
            case 0x23:
                // INC IX
                instruction = INC16(operand: self.IX)
                instructionLength = 2
                
            case 0x29:
                // ADD IX, IX
                instruction = ADD16(op1: self.IX, op2: self.IX)
                instructionLength = 2
                
            case 0x2B:
                // DEC IX
                instruction = DEC16(operand: self.IX)
                instructionLength = 2
                
            case 0x34:
                // INC (IX+d)
                let displacement = bus.readSigned(PC.read()+2)
                instruction = INC8(operand: Indexed8(register: self.IX, displacement: displacement, bus: self.bus))
                instructionLength = 3
                
            case 0x35:
                // DEC (IX+d)
                let displacement = bus.readSigned(PC.read()+2)
                instruction = DEC8(operand: Indexed8(register: self.IX, displacement: displacement, bus: self.bus))
                instructionLength = 3
                
            case 0x39:
                // ADD IX, SP
                instruction = ADD16(op1: self.IX, op2: self.SP)
                instructionLength = 2
                
            case 0xE5:
                // PUSH IX
                instruction = PUSH(operand: self.IX)
                instructionLength = 2
                
            case 0xE9:
                // JP (IX)
                instruction = JP(condition: nil, dest: self.IX)
                instructionLength = 1
                
            default:
                let combinedOpcode: UInt16 = make16(high: firstByte, low: secondByte)
                print(String(format: "Unrecognized opcode 0x%04X at PC 0x%04X", combinedOpcode, PC.read()))
            }
            
        case 0xFD:
            // IY instructions
            //@todo it wouldn't be very hard to make some higher-level code that handles both
            //IX instructions and IY instructions
            let secondByte = bus.read(PC.read()+1)
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