//
//  LR35902.swift
//  ostrichframework
//
//  Created by Ryan Conway on 4/6/16.
//  Copyright © 2016 Ryan Conway. All rights reserved.
//

import Foundation


/// Representation of a Sharp LR35902 CPU.
public class LR35902: Intel8080Like {
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
    
    /// stack pointer
    let SP: Register16
    
    // other registers
    /// interrupt page address
    let I: Register8
    /// memory refresh
    let R: Register8
    
    /// program counter
    let PC: Register16
    
    // flags - computed from F
    /// Zero flag
    let ZF: Flag
    /// Ssubtract flag
    let NF: Flag
    /// Half-carry flag
    let HF: Flag
    /// Carry flag
    let CF: Flag
    
    // logical 16-bit main registers
    let AF: Register16Computed
    let BC: Register16Computed
    let DE: Register16Computed
    let HL: Register16Computed
    
    /// interrupt
    var IFF1: FlipFlop
    var IFF2: FlipFlop
    
    var instructionContext: Intel8080InstructionContext
    
    let bus: DataBus
    
    public init(bus: DataBus) {
        func random8() -> UInt8 {
            return UInt8(truncatingBitPattern: arc4random() % 256)
        }
        
        self.A = Register8(val: 0xFF)
        self.B = Register8(val: random8())
        self.C = Register8(val: random8())
        self.D = Register8(val: random8())
        self.E = Register8(val: random8())
        self.F = Register8(val: 0xFF)
        self.H = Register8(val: random8())
        self.L = Register8(val: random8())
        
        self.SP = Register16(val: 0xFFFF)
        
        self.I = Register8(val: random8())
        self.R = Register8(val: random8())
        
        self.PC = Register16(val: 0x0000)
        
        self.ZF = Flag(reg: F, bitNumber: 7)
        self.NF = Flag(reg: F, bitNumber: 6)
        self.HF = Flag(reg: F, bitNumber: 5)
        self.CF = Flag(reg: F, bitNumber: 4)
        
        self.AF = Register16Computed(high: self.A, low: self.F)
        self.BC = Register16Computed(high: self.B, low: self.C)
        self.DE = Register16Computed(high: self.D, low: self.E)
        self.HL = Register16Computed(high: self.H, low: self.L)
        
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
    
    
    public func runUntilRet() {
        //@todo this is a hacky convenience function, how can we better detect a given instruction without inspecting type?
        var callsDeep = 1
        repeat {
            let lastInstruction = doInstructionCycle()
            let inspectedType = String(Mirror(reflecting: lastInstruction).subjectType)
            if inspectedType.rangeOfString("CALL") != nil {
                callsDeep += 1
            } else if inspectedType.rangeOfString("RET") != nil {
                callsDeep -= 1
                
                if callsDeep == 0 {
                    return
                }
            }
        } while true
    }
    
    
    /// Fetches an instruction, runs it, and returns it
    func doInstructionCycle() -> LR35902Instruction {
        guard let instruction = self.fetchInstruction() else {
            print("FATAL: unable to fetch instruction")
            exit(1)
        }
        self.executeInstruction(instruction)
        
        return instruction
    }
    
    /// Execute an instruction.
    /// This function has some additional behavior to support things like EI, which has effects delayed by an instruction.
    func executeInstruction(instruction: LR35902Instruction) {
        let willEnableInterrupts = self.instructionContext.lastInstructionWasEI
        
        instruction.runOn(self)
        
        if willEnableInterrupts {
            self.IFF1 = .Enabled
            self.IFF2 = .Enabled
            
            //@warn this behavior may be too lazy
            self.instructionContext.lastInstructionWasEI = false
        }
    }
    
    //@todo make this internal and add a public run() or clock() or something
    func fetchInstruction() -> LR35902Instruction? {
        var instruction: LR35902Instruction? = nil
        var instructionLength: UInt16 = 1
        
        if let commonInstruction = self.fetchInstructionCommon() {
            if let i = commonInstruction as? LR35902Instruction {
                instruction = i
            }
        }
        
        if instruction == nil {
            let firstByte = bus.read(PC.read())
            
            switch firstByte {
            case 0x2A:
                // LD A, (HL+)
                instruction = LDI_LR(pointable: self.HL, other: self.A, direction: .OutOfPointer)
                instructionLength = 1
                
            case 0xD9:
                // RETI
                instruction = RETI()
                instructionLength = 1
                
            case 0xE0:
                // LDH (n), A
                let offset = bus.read(PC.read()+1)
                instruction = LDHNA(offset: offset)
                instructionLength = 2
                
            case 0xE2:
                // LD (C), A
                instruction = LDCA()
                instructionLength = 1
                
            case 0xE8:
                // ADD SP, n
                let value = Int8(bitPattern: bus.read(PC.read()+1))
                instruction = ADDSP(value: value)
                instructionLength = 2
                
            case 0xEA:
                // LD (nn), A
                let val = bus.read16(PC.read()+1)
                instruction = LD(dest: Pointer(source: Immediate16(val: val), bus: bus), src: self.A)
                instructionLength = 3
                
            case 0xF0:
                // LDH A, (n)
                let offset = bus.read(PC.read()+1)
                instruction = LDHAN(offset: offset)
                instructionLength = 2
                
            case 0xF2:
                // LD A, (C)
                instruction = LDAC()
                instructionLength = 1
                
            case 0xFA:
                // LD A, (nn)
                let val = bus.read16(PC.read()+1)
                instruction = LD(dest: self.A, src: Pointer(source: Immediate16(val: val), bus: bus))
                instructionLength = 3
                
            default:
                break
            }
            
            if let instruction = instruction {
                print("L \(PC.read().hexString): ", terminator: "")
                for i in 0..<instructionLength {
                    print("\(bus.read(PC.read()+i).hexString) ", terminator: "")
                }
                print("\n\t\(instruction)\n")
                
                //@todo make PC-incrementing common
                self.PC.write(self.PC.read() + instructionLength)
            }
        }
        
        return instruction
    }
}