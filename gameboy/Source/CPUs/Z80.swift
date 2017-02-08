//
//  Z80.swift
//  ostrich
//
//  Created by Ryan Conway on 1/6/16.
//  Copyright © 2016 conwarez. All rights reserved.
//

import Foundation


/// Representation a Zilog Z80 CPU.
open class Z80: Intel8080Like {
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
        
        self.PC = Register16(val: 0)
        
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
        
        
        self.IFF1 = .disabled
        self.IFF2 = .disabled
        
        self.instructionContext = Intel8080InstructionContext(lastInstructionWasDI: false, lastInstructionWasEI: false)
        
        self.bus = bus
    }
    
    // Utility methods
    open func setSP(_ sp: Address) {
        self.SP.write(sp)
    }
    
    open func setPC(_ pc: Address) {
        self.PC.write(pc)
    }
    
    open func setA(_ a: UInt8) {
        self.A.write(a)
    }
    
    open func injectCall(_ addr: Address) {
        let instruction = CALL(condition: nil, dest: Immediate16(val: addr))
        instruction.runOn(self)
    }
    
    /// Stack pointer and program counter debug string
    var pcsp: String { return "\tSP: \(self.SP.read().hexString)\n\tPC: \(self.PC.read().hexString)" }

    
    open func runUntil(_ instructionType: String) {
        //@todo this is a hacky convenience function, how can we better detect a given instruction without inspecting type?
        var iteration = 1
        repeat {
            let lastInstruction = doInstructionCycle()
            iteration += 1
            let inspectedType = String(describing: Mirror(reflecting: lastInstruction).subjectType)
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
    func executeInstruction(_ instruction: Z80Instruction) {
        let oldInstructionContext = self.instructionContext
        
        instruction.runOn(self)
        
        if oldInstructionContext.lastInstructionWasDI {
            self.IFF1 = .disabled
            self.IFF2 = .disabled
            
            //@warn this behavior may be too lazy
            self.instructionContext.lastInstructionWasDI = false
        }
        if oldInstructionContext.lastInstructionWasEI {
            self.IFF1 = .enabled
            self.IFF2 = .enabled
            
            //@warn this behavior may be too lazy
            self.instructionContext.lastInstructionWasEI = false
        }
    }
    
    //@todo make this internal and add a public run() or clock() or something
    func fetchInstruction() -> Z80Instruction? {
        /*
        let firstByte = bus.read(PC.read())
        
        var instruction: Z80Instruction? = nil
        var instructionLength: UInt16 = 1
        
        switch firstByte {
        case 0x08:
            // EX AF, AF'
            instruction = EX(op1: self.AF, op2: self.AFp)
            instructionLength = 1
            
        case 0x10:
            // DJNZ
            let displacementMinusTwo = Int8(bitPattern: bus.read(PC.read()+1))
            instruction = DJNZ(displacementMinusTwo: displacementMinusTwo)
            instructionLength = 2
            
            
        case 0xE0:
            // RET po
            instruction = RET(condition: Condition(flag: self.PVF, target: false))
            instructionLength = 1
            
        case 0xE2:
            // JP po, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.PVF, target: false), dest: Immediate16(val: addr))
            instructionLength = 3
            
        case 0xE8:
            // RET pe
            instruction = RET(condition: Condition(flag: self.PVF, target: true))
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
            
        case 0xF8:
            // RET p
            instruction = RET(condition: Condition(flag: self.SF, target: false))
            instructionLength = 1
            
        case 0xFA:
            // JP m, nn
            let addr = bus.read16(PC.read()+1)
            instruction = JP(condition: Condition(flag: self.SF, target: true), dest: Immediate16(val: addr))
            instructionLength = 3
           
            
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
         */
        
        return nil
    }
}
